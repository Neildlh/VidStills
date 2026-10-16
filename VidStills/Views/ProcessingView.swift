import SwiftUI
import AVFoundation

// Progress bar + cancel during frame extraction.

struct ProcessingView: View {

    let video: VideoFile
    let progress: Double
    let currentFrame: Int
    let totalFrames: Int

    @EnvironmentObject var state: AppState

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.well, style: .continuous)
                .fill(Color.bone)

            RoundedRectangle(cornerRadius: AppRadius.well, style: .continuous)
                .strokeBorder(Color.dashedBorder, style: StrokeStyle(lineWidth: 1.25, dash: [6, 5]))

            VStack(spacing: Spacing.s6) {

                VStack(spacing: Spacing.s2) {
                    Text("EXTRACTING")
                        .captionStyle()
                    Text(video.displayName)
                        .font(AppFont.title(18, weight: .semibold))
                        .foregroundColor(.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .truncationMode(.middle)
                        .frame(maxWidth: 400)
                }

                // — Progress bar
                VStack(spacing: Spacing.s2) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.ink.opacity(0.10))
                                .frame(height: 6)
                            Capsule()
                                .fill(Color.flame)
                                .frame(width: geo.size.width * progress, height: 6)
                                .animation(.linear(duration: 0.12), value: progress)
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Text("\(currentFrame) / \(totalFrames) frames")
                            .font(AppFont.mono(11))
                            .foregroundColor(.mutedInk)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(AppFont.mono(11, weight: .semibold))
                            .foregroundColor(.ink)
                    }
                }
                .padding(.horizontal, Spacing.s2)

                Spacer().frame(height: Spacing.s2)

                SecondaryButton(title: "Cancel") {
                    state.cancelExtraction()
                }
            }
            .padding(.horizontal, Spacing.s6)
            .padding(.vertical, Spacing.s10)
        }
    }
}

#Preview {
    ProcessingView(
        video: VideoFile(
            url: URL(fileURLWithPath: "/Users/me/Movies/Clip.mov"),
            displayName: "Clip.mov",
            resolution: CGSize(width: 1920, height: 1080),
            duration: CMTime(seconds: 73, preferredTimescale: 600),
            nominalFrameRate: 30,
            estimatedFrameCount: 2190,
            fileSize: 0
        ),
        progress: 0.42,
        currentFrame: 920,
        totalFrames: 2190
    )
    .environmentObject(AppState())
    .padding(48)
    .background(Color.chamois)
    .frame(width: 560, height: 640)
}
