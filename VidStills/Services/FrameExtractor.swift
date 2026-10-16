import Foundation
import AVFoundation
import CoreImage
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// MARK: - Output format

enum FrameOutputFormat: Sendable {
    case jpeg(quality: CGFloat)   // 0.0 ... 1.0; 0.9 is the practical sweet spot
    case png

    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png:  return "png"
        }
    }

    var utType: CFString {
        switch self {
        case .jpeg: return UTType.jpeg.identifier as CFString
        case .png:  return UTType.png.identifier  as CFString
        }
    }

    var imageDestinationOptions: [CFString: Any] {
        switch self {
        case .jpeg(let q):
            return [kCGImageDestinationLossyCompressionQuality: q]
        case .png:
            return [:]
        }
    }
}

// MARK: - Errors

enum FrameExtractorError: Error {
    case unreadable
    case unsupportedFormat
    case writeDenied
    case diskFull
    case unknown

    var userMessage: String {
        switch self {
        case .unreadable:        return "VidStills can't read this file."
        case .unsupportedFormat: return "This video format isn't supported."
        case .writeDenied:       return "VidStills doesn't have permission to write here. Choose a different folder."
        case .diskFull:          return "Not enough space to save all frames."
        case .unknown:           return "Something went wrong while extracting frames."
        }
    }
}

// MARK: - FrameExtractor
//
// Reads the video sequentially via `AVAssetReader` + `AVAssetReaderTrackOutput`
// — which is Apple's documented "extract every frame" pattern, not the
// thumbnail-oriented `AVAssetImageGenerator`. This eliminates the entire class
// of `AVError.decodeError` failures that the zero-tolerance image-generator
// path triggers on modern codecs (especially HEVC screen recordings).

actor FrameExtractor {

    typealias ProgressCallback = @Sendable (_ current: Int, _ total: Int) -> Void

    func extract(
        source url: URL,
        output folder: URL,
        format: FrameOutputFormat = .jpeg(quality: 0.9),
        expectedFrameCount expected: Int,
        progress: @escaping ProgressCallback
    ) async throws -> Int {

        let asset = AVURLAsset(url: url)

        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw FrameExtractorError.unsupportedFormat
        }

        let preferredTransform = try await track.load(.preferredTransform)
        let total = max(expected, 1)
        let padWidth = String(total).count

        // Build the reader/output pair.
        let reader: AVAssetReader
        do {
            reader = try AVAssetReader(asset: asset)
        } catch {
            throw FrameExtractorError.unreadable
        }

        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        trackOutput.alwaysCopiesSampleData = false

        guard reader.canAdd(trackOutput) else {
            throw FrameExtractorError.unsupportedFormat
        }
        reader.add(trackOutput)

        guard reader.startReading() else {
            throw mapReaderError(reader)
        }

        // CIContext is reused across frames for performance. GPU-backed by default.
        let context = CIContext(options: nil)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()

        var written = 0
        var encounteredError: Error?

        // Sequential read loop. We hop off the actor each iteration so SwiftUI
        // progress callbacks can land on the main actor without contention.
        readLoop: while reader.status == .reading {
            // Cancellation point.
            do { try Task.checkCancellation() }
            catch {
                reader.cancelReading()
                throw error
            }

            guard let sample = trackOutput.copyNextSampleBuffer() else { break }

            // Some sample buffers may be marker/empty; skip those.
            guard CMSampleBufferDataIsReady(sample) else { continue }
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sample) else { continue }

            do {
                let index = written + 1
                let filename = "frame_\(String(format: "%0\(padWidth)d", index)).\(format.fileExtension)"
                let fileURL = folder.appendingPathComponent(filename)

                try writeFrame(
                    pixelBuffer: pixelBuffer,
                    transform: preferredTransform,
                    context: context,
                    colorSpace: colorSpace,
                    format: format,
                    to: fileURL
                )
                written += 1
                progress(written, total)
            } catch let err as NSError {
                if err.domain == NSCocoaErrorDomain {
                    if err.code == NSFileWriteOutOfSpaceError {
                        encounteredError = FrameExtractorError.diskFull
                        break readLoop
                    }
                    if err.code == NSFileWriteNoPermissionError {
                        encounteredError = FrameExtractorError.writeDenied
                        break readLoop
                    }
                }
                encounteredError = FrameExtractorError.unknown
                break readLoop
            }
        }

        // If we exited the loop with an error, surface it.
        if let encounteredError {
            reader.cancelReading()
            throw encounteredError
        }

        // The reader may report failure even if we wrote frames successfully.
        switch reader.status {
        case .failed:
            throw mapReaderError(reader)
        case .cancelled:
            throw CancellationError()
        case .completed, .reading, .unknown:
            break
        @unknown default:
            break
        }

        return written
    }

    // MARK: - Helpers

    private func writeFrame(
        pixelBuffer: CVPixelBuffer,
        transform: CGAffineTransform,
        context: CIContext,
        colorSpace: CGColorSpace,
        format: FrameOutputFormat,
        to url: URL
    ) throws {
        // 1) Pixel buffer → CIImage
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // 2) Apply the track's preferred transform (handles portrait / rotated video)
        if !transform.isIdentity {
            ciImage = ciImage.transformed(by: transform)
            // Re-anchor to origin so the rendered extent starts at (0,0).
            let origin = ciImage.extent.origin
            if origin != .zero {
                ciImage = ciImage.transformed(by: CGAffineTransform(translationX: -origin.x, y: -origin.y))
            }
        }

        // 3) CIImage → CGImage (rendered in sRGB)
        guard let cgImage = context.createCGImage(
            ciImage,
            from: ciImage.extent,
            format: .RGBA8,
            colorSpace: colorSpace
        ) else {
            throw FrameExtractorError.unknown
        }

        // 4) Write via ImageIO with format-specific options.
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, format.utType, 1, nil) else {
            throw FrameExtractorError.unknown
        }
        CGImageDestinationAddImage(dest, cgImage, format.imageDestinationOptions as CFDictionary)
        if !CGImageDestinationFinalize(dest) {
            throw FrameExtractorError.unknown
        }
    }

    private func mapReaderError(_ reader: AVAssetReader) -> Error {
        // AVAssetReader surfaces detailed NSErrors; map a few common ones.
        guard let nsError = reader.error as NSError? else {
            return FrameExtractorError.unsupportedFormat
        }
        // AVFoundation error codes we care about:
        //   -11800  AVErrorUnknown
        //   -11819  AVErrorMediaServicesWereReset
        //   -11828  AVErrorFileFormatNotRecognized
        //   -11829  AVErrorFileFailedToParse
        //   -11848  AVErrorContentIsNotAuthorized
        switch nsError.code {
        case -11828, -11829:
            return FrameExtractorError.unsupportedFormat
        case -11848:
            return FrameExtractorError.unreadable
        default:
            return FrameExtractorError.unsupportedFormat
        }
    }
}
