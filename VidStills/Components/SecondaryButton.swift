import SwiftUI

// Outlined, ink-bordered button. Inverts on hover (ink fill, bone text).
struct SecondaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.button(13))
                .tracking(0.13)
                .foregroundColor(isHovering ? .bone : .ink)
                .padding(.horizontal, Spacing.s5 - 2)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                        .fill(isHovering ? Color.ink : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                        .stroke(Color.inkOutline, lineWidth: 1)
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
        SecondaryButton(title: "Browse…") {}
        SecondaryButton(title: "Cancel") {}
    }
    .padding(48)
    .background(Color.chamois)
}
