import SwiftUI

/// An authored, still pixel city beyond the apartment. Separate from furniture
/// and people so every room layer remains interactive and independently lit.
struct ApartmentNightBackdrop: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [Color(red: 0.035, green: 0.065, blue: 0.10),
                                         Color(red: 0.09, green: 0.16, blue: 0.20),
                                         Color(red: 0.16, green: 0.13, blue: 0.12)],
                               startPoint: .top, endPoint: .bottom)
                Canvas { context, size in
                    let unit = max(2, floor(size.width / 130))
                    func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color) {
                        context.fill(Path(CGRect(x: floor(x / unit) * unit,
                                                 y: floor(y / unit) * unit,
                                                 width: ceil(w / unit) * unit,
                                                 height: ceil(h / unit) * unit)), with: .color(color))
                    }
                    // Distant stars are small and sparse; broad cloud banks carry
                    // the sky's depth without repeated decorative sparkles.
                    for index in 0..<19 {
                        let x = CGFloat((index * 47 + 17) % 131) / 131 * size.width
                        let y = CGFloat((index * 31 + 11) % 79) / 160 * size.height
                        rect(x, y, unit, unit, .init(red: 0.61, green: 0.70, blue: 0.73).opacity(index % 3 == 0 ? 0.55 : 0.22))
                    }
                    for bank in 0..<3 {
                        let x = CGFloat(bank) * size.width * 0.41 - size.width * 0.12
                        let y = size.height * (0.12 + CGFloat(bank) * 0.09)
                        for step in 0..<6 {
                            rect(x + CGFloat(step) * 19, y + CGFloat(abs(step - 3)) * 3,
                                 44, 7, Color(red: 0.18, green: 0.26, blue: 0.30).opacity(0.25))
                        }
                    }
                    // Two skyline depths, with individually placed lit windows,
                    // rooftop water tanks and cornices rather than identical bars.
                    for depth in 0..<2 {
                        let count = depth == 0 ? 11 : 7
                        let width = size.width / CGFloat(count)
                        for column in 0..<count {
                            let roof = size.height * (0.30 + CGFloat((column * 7 + depth * 3) % 9) * 0.023 + CGFloat(depth) * 0.17)
                            let x = CGFloat(column) * width
                            let wall = depth == 0 ? Color(red: 0.055, green: 0.105, blue: 0.145) : Color(red: 0.045, green: 0.075, blue: 0.10)
                            rect(x, roof, width - unit, size.height - roof, wall)
                            rect(x - unit, roof, width + unit, unit * 2, .init(red: 0.16, green: 0.21, blue: 0.23).opacity(0.6))
                            if column % 3 == 0 {
                                rect(x + width * 0.35, roof - unit * 8, width * 0.35, unit * 6, wall)
                                rect(x + width * 0.3, roof - unit * 9, width * 0.45, unit * 2, wall)
                            }
                            for row in 0..<12 {
                                for pane in 0..<2 {
                                    let lit = (column * 13 + row * 7 + pane * 3 + depth) % 5 < 2
                                    rect(x + width * (pane == 0 ? 0.18 : 0.61), roof + 17 + CGFloat(row) * 26,
                                         width * 0.16, 9,
                                         lit ? Color(red: 0.96, green: 0.66, blue: 0.28).opacity(depth == 0 ? 0.25 : 0.40) : Color.white.opacity(0.025))
                                }
                            }
                        }
                    }
                }
                LinearGradient(colors: [.clear, Color.black.opacity(0.5)], startPoint: .center, endPoint: .bottom)
                RadialGradient(colors: [Color(red: 1, green: 0.62, blue: 0.22).opacity(0.12), .clear],
                               center: .bottomTrailing, startRadius: 0, endRadius: geometry.size.height * 0.65)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}
