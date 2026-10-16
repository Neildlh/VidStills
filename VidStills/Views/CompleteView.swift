import SwiftUI
import AVFoundation

// Shown when extraction finishes successfully.

struct CompleteView: View {

    let video: VideoFile
    let outputFolder: URL
    let frameCount: Int

    @EnvironmentObject var state: AppState

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.well, style: .continuous)
                .fill(Color.bone)

            RoundedRectangle(cornerRadius: AppRadius.well, style: .continuous)
                .strokeBorder(Color.dashedBorder, style: StrokeStyle(lineWidth: 1.25, dash: [6, 5]))

            VStack(spacing: Spacing.s6) {

                VStack(spacing: Spacing.s2) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.bone)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.flame))

                    Text("DONE")
                        .captionStyle()
                        .padding(.top, Spacing.s2)
                }

                VStack(spacing: Spacing.s1 + 2) {
                    Text("\(frameCount) stills extracted")
                        .font(AppFont.title(22, weight: .semibold))
                        .foregroundColor(.ink)
                    Text("Saved to \(outputFolder.lastPathComponent)/")
                        .font(AppFont.body(13))
                        .foregroundColor(.mutedInk)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 380)
                }

                Spacer().frame(height: Spacing.s2)

                PrimaryButton(title: "Reveal in Finder") {
                    state.revealInFinder(outputFolder)
                }

                Button("Convert another video") {
                    state.reset()
                }
                .buttonStyle(.plain)
                .font(AppFont.button(12, weight: .medium))
                .foregroundColor(.mutedInk)
            }
            .padding(.horizontal, Spacing.s6)
            .padding(.vertical, Spacing.s10)
        }
    }
}

#Preview {
    CompleteView(
        video: VideoFile(
            url: URL(fileURLWithPath: "/Users/me/Movies/Clip.mov"),
            displayName: "Clip.mov",
            resolution: CGSize(width: 1920, height: 1080),
            duration: CMTime(seconds: 73, preferredTimescale: 600),
            nominalFrameRate: 30,
            estimatedFrameCount: 2190,
            fileSize: 0
        ),
        outputFolder: URL(fileURLWithPath: "/Users/me/Movies/Stills"),
        frameCount: 2190
    )
    .environmentObject(AppState())
    .padding(48)
    .background(Color.chamois)
    .frame(width: 560, height: 640)
}
