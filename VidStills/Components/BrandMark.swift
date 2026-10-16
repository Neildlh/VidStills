import SwiftUI

// MARK: - BrandMark (header)
//
// Three-stacked "stills" on a dark tile. Two cream-outlined frames stacked behind
// a solid flame frame. Mirrors the macOS app icon so the in-window identity
// matches the Dock tile.
struct BrandMark: View {
    var size: CGFloat = 36
    var rounded: Bool = true

    var body: some View {
        let unit = size / 32
        let stroke = max(1.25, size / 28)
        let radius = rounded ? size * 0.2237 : 0

        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color.ink)

            // back frame — cream outline, top-left
            Rectangle()
                .stroke(Color.chamois, lineWidth: stroke)
                .frame(width: 14 * unit, height: 14 * unit)
                .offset(x: (6 + 7 - 16) * unit, y: (6 + 7 - 16) * unit)

            // mid frame — cream outline, offset down-right
            Rectangle()
                .stroke(Color.chamois, lineWidth: stroke)
                .frame(width: 14 * unit, height: 14 * unit)
                .offset(x: (9 + 7 - 16) * unit, y: (9 + 7 - 16) * unit)

            // front frame — solid flame, foreground "still"
            Rectangle()
                .fill(Color.flame)
                .frame(width: 14 * unit, height: 14 * unit)
                .offset(x: (12 + 7 - 16) * unit, y: (12 + 7 - 16) * unit)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("VidStills")
    }
}

// MARK: - FilmstripGlyph (drop-well icon, per VidStills v1)
//
// A filmstrip aperture: square frame with four sprocket marks at the corners
// and a flame-coloured slit punched out of its centre. Reads cleanly at any size.
struct FilmstripGlyph: View {
    var size: CGFloat = 56

    var body: some View {
        Canvas { ctx, _ in
            // 8-unit grid → keep the geometry crisp at any rendered size.
            let u = size / 8

            // outer aperture ring (1u stroke, drawn as a stroked rect)
            let ring = CGRect(x: 0.5 * u, y: 0.5 * u, width: 7 * u, height: 7 * u)
            ctx.stroke(Path(ring), with: .color(.ink), lineWidth: u * 1.0)

            // perforation marks — film sprocket cadence
            let perfSize = 0.5 * u
            let perfPositions: [(CGFloat, CGFloat)] = [
                (1.25, 1.25), (6.25, 1.25), (1.25, 6.25), (6.25, 6.25)
            ]
            for (x, y) in perfPositions {
                let rect = CGRect(x: x * u, y: y * u, width: perfSize, height: perfSize)
                ctx.fill(Path(rect), with: .color(.ink))
            }

            // flame slit — the single moment of colour
            let slit = CGRect(x: 3.5 * u, y: 2 * u, width: 1 * u, height: 4 * u)
            ctx.fill(Path(slit), with: .color(.flame))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview("BrandMark") {
    VStack(spacing: 24) {
        BrandMark(size: 36)
        BrandMark(size: 64)
        FilmstripGlyph(size: 56)
        FilmstripGlyph(size: 96)
    }
    .padding(48)
    .background(Color.chamois)
}
