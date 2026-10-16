import SwiftUI

// Shown for any failure mode. Always offers "Try again".

struct ErrorBannerView: View {

    let message: String
    @EnvironmentObject var state: AppState

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.well, style: .continuous)
                .fill(Color.bone)

            RoundedRectangle(cornerRadius: AppRadius.well, style: .continuous)
                .strokeBorder(Color.dashedBorder, style: StrokeStyle(lineWidth: 1.25, dash: [6, 5]))

            VStack(spacing: Spacing.s6) {
                ZStack {
                    Circle()
                        .fill(Color.flame.opacity(0.18))
                        .frame(width: 56, height: 56)
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.flame)
                }

                VStack(spacing: Spacing.s2) {
                    Text("SOMETHING WENT WRONG")
                        .captionStyle()
                    Text(message)
                        .font(AppFont.body(15))
                        .foregroundColor(.ink)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                }

                PrimaryButton(title: "Try again") {
                    state.tryAgain()
                }
            }
            .padding(.horizontal, Spacing.s6)
            .padding(.vertical, Spacing.s10)
        }
    }
}

#Preview {
    ErrorBannerView(message: "VidStills can't read this file.")
        .environmentObject(AppState())
        .padding(48)
        .background(Color.chamois)
        .frame(width: 560, height: 640)
}
