import SwiftUI
import AVFoundation

// Shown after the user picks a video. Displays file info and the Extract CTA.

struct FileLoadedView: View {

    let video: VideoFile
    @EnvironmentObject var state: AppState

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.well, style: .continuous)
                .fill(Color.bone)

            RoundedRectangle(cornerRadius: AppRadius.well, style: .continuous)
                .strokeBorder(Color.dashedBorder, style: StrokeStyle(lineWidth: 1.25, dash: [6, 5]))

            VStack(spacing: Spacing.s6) {

                // — Header (file name + spec readout)
                VStack(spacing: Spacing.s2) {
                    Text("READY")
                        .captionStyle()

                    Text(video.displayName)
                        .font(AppFont.title(20, weight: .semibold))
                        .foregroundColor(.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .truncationMode(.middle)
                        .frame(maxWidth: 400)
                }

                // — Spec strip: resolution / duration / framerate / total frames
                specStrip

                Spacer().frame(height: Spacing.s2)

                // — Primary CTA. Trailing ellipsis = macOS convention for
                // "next click opens a modal" (folder picker).
                VStack(spacing: Spacing.s2) {
                    PrimaryButton(title: "Extract every frame…") {
                        state.startExtraction()
                    }
                    Text("You'll choose where to save the JPGs next.")
                        .font(AppFont.body(12))
                        .foregroundColor(.mutedInk)
                }

                Button("Choose a different video") {
                    state.reset()
                }
                .buttonStyle(.plain)
                .font(AppFont.button(12, weight: .medium))
                .foregroundColor(.mutedInk)
            }
            .padding(.horizontal, Spacing.s6)
            .padding(.vertical, Spacing.s8)
        }
    }

    // MARK: - Spec strip

    private var specStrip: some View {
        HStack(spacing: 0) {
            specCell(label: "RES", value: "\(Int(video.resolution.width))×\(Int(video.resolution.height))")
            divider
            specCell(label: "LEN", value: durationString)
            divider
            specCell(label: "FPS", value: String(format: "%.2f", video.nominalFrameRate))
            divider
            specCell(label: "FRAMES", value: "\(video.estimatedFrameCount)")
        }
        .background(Color.ink.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.ink.opacity(0.18), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
        // The divider Rectangles are greedy; pin the strip to its content height.
        .fixedSize(horizontal: false, vertical: true)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.ink.opacity(0.18))
            .frame(width: 1)
    }

    private func specCell(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(AppFont.mono(9, weight: .semibold))
                .tracking(0.4)
                .foregroundColor(.ink)
            Text(value)
                .font(AppFont.mono(11))
                .foregroundColor(.mutedInk)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Derived

    private var durationString: String {
        let secs = CMTimeGetSeconds(video.duration)
        let totalSeconds = Int(secs.rounded())
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

#Preview {
    FileLoadedView(video: VideoFile(
        url: URL(fileURLWithPath: "/Users/me/Movies/Test Footage.mov"),
        displayName: "Test Footage.mov",
        resolution: CGSize(width: 1920, height: 1080),
        duration: CMTime(seconds: 73, preferredTimescale: 600),
        nominalFrameRate: 29.97,
        estimatedFrameCount: 2188,
        fileSize: 0
    ))
    .environmentObject(AppState())
    .padding(48)
    .background(Color.chamois)
    .frame(width: 560, height: 640)
}
