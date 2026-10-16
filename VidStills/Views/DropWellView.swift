import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

// MARK: - Dashed bone-coloured drop well for the empty/idle state.

struct DropWellView: View {

    @EnvironmentObject var state: AppState
    @State private var isTargeted = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.well, style: .continuous)
                .fill(Color.bone)

            // Dashed border, exact spec
            RoundedRectangle(cornerRadius: AppRadius.well, style: .continuous)
                .strokeBorder(
                    isTargeted ? Color.flame.opacity(0.75) : Color.dashedBorder,
                    style: StrokeStyle(
                        lineWidth: isTargeted ? 1.5 : 1.25,
                        dash: [6, 5]
                    )
                )
                .animation(.easeOut(duration: 0.16), value: isTargeted)

            VStack(spacing: Spacing.s6) {
                // Drop-well icon — filmstrip aperture from VidStills v1.
                FilmstripGlyph(size: 56)

                VStack(spacing: Spacing.s1 + 2) {
                    Text("Drop a video here")
                        .font(AppFont.title(20, weight: .semibold))
                        .foregroundColor(.ink)
                        .tracking(-0.1)
                    Text("Every frame becomes a JPG, at the video's native resolution.")
                        .font(AppFont.body(14))
                        .foregroundColor(.mutedInk)
                        .multilineTextAlignment(.center)
                }

                SecondaryButton(title: "Browse…") {
                    state.browseForVideo()
                }
                .padding(.top, Spacing.s1)

                Text("MP4 · MOV · M4V · HEVC · ProRes")
                    .captionStyle()
                    .padding(.top, Spacing.s1)
            }
            .padding(.horizontal, Spacing.s6)
            .padding(.vertical, Spacing.s10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
    }

    // MARK: - Drag handling

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            var url: URL?
            if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            } else if let direct = item as? URL {
                url = direct
            } else if let s = item as? String, let u = URL(string: s) {
                url = u
            }
            guard let resolved = url else { return }

            Task { @MainActor in
                if Self.isAcceptableVideo(at: resolved) {
                    state.handleDroppedURL(resolved)
                } else {
                    state.phase = .error("This video format isn't supported.")
                }
            }
        }
        return true
    }

    private static func isAcceptableVideo(at url: URL) -> Bool {
        // Accept anything that conforms to .movie / .video / .audiovisualContent.
        guard let type = UTType(filenameExtension: url.pathExtension.lowercased()) else { return false }
        return type.conforms(to: .movie)
            || type.conforms(to: .video)
            || type.conforms(to: .audiovisualContent)
    }
}

#Preview {
    DropWellView()
        .environmentObject(AppState())
        .padding(48)
        .background(Color.chamois)
        .frame(width: 560, height: 640)
}
