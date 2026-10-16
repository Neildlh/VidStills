import SwiftUI

struct ContentView: View {

    @StateObject private var state = AppState()

    var body: some View {
        ZStack(alignment: .top) {
            Color.chamois
                .ignoresSafeArea()

            VStack(spacing: Spacing.s6) {
                header

                bodyContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Footer()
            }
            .padding(.top, Spacing.s12)
            .padding(.horizontal, Spacing.s12)
            .padding(.bottom, Spacing.s6)
        }
        .frame(width: WindowSize.width, height: WindowSize.height)
        .environmentObject(state)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.s3 + 2) {
            BrandMark(size: 36)
            Text("VidStills")
                .font(AppFont.display(32, weight: .semibold))
                .tracking(-0.48)
                .foregroundColor(.ink)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Phase routing

    @ViewBuilder
    private var bodyContent: some View {
        switch state.phase {
        case .idle:
            DropWellView()
        case .loaded(let video):
            FileLoadedView(video: video)
        case .processing(let video, let progress, let current, let total):
            ProcessingView(
                video: video,
                progress: progress,
                currentFrame: current,
                totalFrames: total
            )
        case .complete(let video, let folder, let count):
            CompleteView(
                video: video,
                outputFolder: folder,
                frameCount: count
            )
        case .error(let message):
            ErrorBannerView(message: message)
        }
    }
}

// MARK: - Footer

private struct Footer: View {
    var body: some View {
        Text("Frame Extractor")
            .captionStyle()
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    ContentView()
}
