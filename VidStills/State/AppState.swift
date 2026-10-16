import Foundation
import AVFoundation
import AppKit
import Combine
import UniformTypeIdentifiers

// MARK: - VideoFile

struct VideoFile: Equatable, Identifiable {
    let id = UUID()
    let url: URL
    let displayName: String
    let resolution: CGSize
    let duration: CMTime
    let nominalFrameRate: Float
    let estimatedFrameCount: Int
    let fileSize: Int64

    static func == (lhs: VideoFile, rhs: VideoFile) -> Bool { lhs.id == rhs.id }
}

// MARK: - Phase

enum Phase: Equatable {
    case idle
    case loaded(VideoFile)
    case processing(VideoFile, progress: Double, currentFrame: Int, totalFrames: Int)
    case complete(VideoFile, outputFolder: URL, frameCount: Int)
    case error(String)

    static func == (lhs: Phase, rhs: Phase) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case let (.loaded(a), .loaded(b)): return a == b
        case let (.processing(va, pa, ca, ta), .processing(vb, pb, cb, tb)):
            return va == vb && pa == pb && ca == cb && ta == tb
        case let (.complete(va, fa, ca), .complete(vb, fb, cb)):
            return va == vb && fa == fb && ca == cb
        case let (.error(a), .error(b)): return a == b
        default: return false
        }
    }
}

// MARK: - AppState

@MainActor
final class AppState: ObservableObject {

    @Published var phase: Phase = .idle

    private var extractionTask: Task<Void, Never>?

    // MARK: Drag-and-drop / file selection entry points

    func handleDroppedURL(_ url: URL) {
        Task { await loadVideo(at: url) }
    }

    func browseForVideo() {
        let panel = NSOpenPanel()
        panel.title = "Choose a video"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.movie, .video, .quickTimeMovie, .mpeg4Movie]

        guard panel.runModal() == .OK, let url = panel.url else { return }
        Task { await loadVideo(at: url) }
    }

    func loadVideo(at url: URL) async {
        do {
            let info = try await Self.probe(url: url)
            phase = .loaded(info)
        } catch {
            phase = .error(Self.message(for: error))
        }
    }

    // MARK: Extraction

    // Ask the user where to save, then extract directly into that folder.
    // No automatic subfolder — picking the destination is the user's decision,
    // so two videos in the same parent don't collide on a "Stills/" name.
    func startExtraction() {
        guard case let .loaded(video) = phase else { return }

        let panel = NSOpenPanel()
        panel.title = "Save stills"
        panel.message = "Choose a folder. Every frame will be saved here as a JPG."
        panel.prompt = "Save here"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = video.url.deletingLastPathComponent()

        guard panel.runModal() == .OK, let outputFolder = panel.url else { return }

        phase = .processing(video, progress: 0, currentFrame: 0, totalFrames: video.estimatedFrameCount)

        extractionTask = Task { [weak self] in
            guard let self else { return }
            let extractor = FrameExtractor()
            do {
                let written = try await extractor.extract(
                    source: video.url,
                    output: outputFolder,
                    expectedFrameCount: video.estimatedFrameCount
                ) { current, total in
                    Task { @MainActor in
                        guard case .processing = self.phase else { return }
                        // The frame total is estimated from duration × fps, so the
                        // real count can run slightly over. Keep the bar at ≤ 100%.
                        let shownTotal = max(total, current)
                        let p = shownTotal > 0 ? Double(current) / Double(shownTotal) : 0
                        self.phase = .processing(video, progress: p, currentFrame: current, totalFrames: shownTotal)
                    }
                }
                await MainActor.run {
                    self.phase = .complete(video, outputFolder: outputFolder, frameCount: written)
                }
            } catch is CancellationError {
                await MainActor.run {
                    self.phase = .loaded(video)
                }
            } catch {
                await MainActor.run {
                    self.phase = .error(Self.message(for: error))
                }
            }
        }
    }

    func cancelExtraction() {
        extractionTask?.cancel()
        extractionTask = nil
    }

    // MARK: Reset

    func reset() {
        cancelExtraction()
        phase = .idle
    }

    func tryAgain() {
        cancelExtraction()
        phase = .idle
    }

    // MARK: Reveal in Finder

    func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    // MARK: Helpers

    private static func probe(url: URL) async throws -> VideoFile {
        let asset = AVURLAsset(url: url)

        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw FrameExtractorError.unsupportedFormat
        }

        let duration = try await asset.load(.duration)
        let nominalRate = try await track.load(.nominalFrameRate)
        let naturalSize = try await track.load(.naturalSize)
        let transform = try await track.load(.preferredTransform)

        // Apply the preferred track transform so portrait/rotated video reports the right WxH.
        let transformed = naturalSize.applying(transform)
        let displaySize = CGSize(width: abs(transformed.width), height: abs(transformed.height))

        let seconds = CMTimeGetSeconds(duration)
        guard seconds.isFinite, seconds > 0, nominalRate > 0 else {
            throw FrameExtractorError.unreadable
        }

        let frameCount = Int((seconds * Double(nominalRate)).rounded())
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0

        return VideoFile(
            url: url,
            displayName: url.lastPathComponent,
            resolution: displaySize,
            duration: duration,
            nominalFrameRate: nominalRate,
            estimatedFrameCount: max(frameCount, 1),
            fileSize: fileSize
        )
    }

    private static func message(for error: Error) -> String {
        if let e = error as? FrameExtractorError {
            return e.userMessage
        }
        let ns = error as NSError
        if ns.domain == NSCocoaErrorDomain {
            switch ns.code {
            case NSFileReadNoSuchFileError, NSFileReadNoPermissionError:
                return "VidStills can't read this file."
            case NSFileWriteOutOfSpaceError:
                return "Not enough space to save all frames."
            case NSFileWriteNoPermissionError:
                return "VidStills doesn't have permission to write here. Choose a different folder."
            default: break
            }
        }
        return "Something went wrong. \(ns.localizedDescription)"
    }
}
