import SwiftUI

// Flame-coloured CTA. Filled background, ink text, subtle hover darkening.
struct PrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.button(13, weight: .semibold))
                .tracking(0.13)
                .foregroundColor(.bone)
                .padding(.horizontal, Spacing.s5)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                        .fill(isHovering && isEnabled ? Color.flameHover : Color.flame)
                )
                .opacity(isEnabled ? 1.0 : 0.45)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onHover { hovering in
            isHovering = hovering
            if hovering && isEnabled {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .animation(.easeOut(duration: 0.16), value: isHovering)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Extract every frame") {}
        PrimaryButton(title: "Disabled", isEnabled: false) {}
    }
    .padding(48)
    .background(Color.chamois)
}
