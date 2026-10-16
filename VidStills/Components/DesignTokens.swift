import SwiftUI

// MARK: - Colour palette

extension Color {
    static let chamois    = Color(red: 0.941, green: 0.898, blue: 0.800) // #F0E5CC — window canvas
    static let bone       = Color(red: 0.969, green: 0.941, blue: 0.875) // #F7F0DF — drop well surface
    static let ink        = Color(red: 0.102, green: 0.094, blue: 0.082) // #1A1815 — primary text
    static let mutedInk   = Color(red: 0.361, green: 0.337, blue: 0.294) // #5C564B — secondary text
    static let flame      = Color(red: 1.000, green: 0.322, blue: 0.212) // #FF5236 — accent / CTA
    static let flameHover = Color(red: 0.902, green: 0.243, blue: 0.145) // #E63E25 — CTA hover

    static let inkOutline    = Color.ink.opacity(0.55)
    static let dashedBorder  = Color.ink.opacity(0.35)
}

// MARK: - Typography

enum AppFont {
    static func display(_ size: CGFloat = 32, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func title(_ size: CGFloat = 20, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func body(_ size: CGFloat = 14, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func button(_ size: CGFloat = 13, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func caption(_ size: CGFloat = 12, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func mono(_ size: CGFloat = 11, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Spacing (4pt grid)

enum Spacing {
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 20
    static let s6: CGFloat = 24
    static let s7: CGFloat = 28
    static let s8: CGFloat = 32
    static let s10: CGFloat = 40
    static let s12: CGFloat = 48
}

// MARK: - Radii

enum AppRadius {
    static let small: CGFloat = 6
    static let medium: CGFloat = 8
    static let well: CGFloat = 8
    static let window: CGFloat = 12
}

// MARK: - Window dimensions

enum WindowSize {
    static let width: CGFloat = 560
    static let height: CGFloat = 640
}

// MARK: - Reusable text styles

struct CaptionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppFont.caption())
            .tracking(0.24)       // ≈ 2% tracking on 12pt
            .textCase(.uppercase)
            .foregroundColor(.mutedInk)
    }
}

extension View {
    func captionStyle() -> some View {
        modifier(CaptionStyle())
    }
}
