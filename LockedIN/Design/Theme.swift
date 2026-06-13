import SwiftUI

// MARK: - Theme (D-04, D-05, D-06)
//
// Foundational design tokens for LockedIN.
// Playful-but-honest: warm amber study-room energy, honest controls, no dark patterns.
// Keep lightweight — this is a 5h build, not a full design system (D-06).

enum Theme {

    // MARK: - Colour Palette

    enum Colour {
        // Backgrounds — warm dark-academia study-room feel
        static let background = Color(red: 0.118, green: 0.098, blue: 0.078)   // #1E190F deep warm brown
        static let surface    = Color(red: 0.196, green: 0.165, blue: 0.129)   // #322A21 warm surface
        static let surfaceMid = Color(red: 0.259, green: 0.220, blue: 0.169)   // #42382B card surface

        // Accent — warm amber/gold (study lamp, honest & energetic)
        static let accent     = Color(red: 1.000, green: 0.714, blue: 0.149)   // #FFB626 amber gold
        static let accentSoft = Color(red: 1.000, green: 0.839, blue: 0.510)   // #FFD682 soft amber

        // Semantic — commitment money (not coins; the two economies must stay distinct)
        static let moneyGreen = Color(red: 0.220, green: 0.780, blue: 0.435)   // #38C76F return/success
        static let forfeitRed = Color(red: 0.929, green: 0.278, blue: 0.278)   // #ED4747 forfeit/warning

        // Text
        static let textPrimary   = Color(red: 0.949, green: 0.914, blue: 0.851) // #F2E9D9 warm cream
        static let textSecondary = Color(red: 0.671, green: 0.620, blue: 0.545) // #AB9E8B muted sand
        static let textOnAccent  = Color(red: 0.118, green: 0.098, blue: 0.078) // dark on bright accent

        // TEST MODE pill — visually distinct amber-on-dark, never hiding what it is
        static let testBadgeBg   = Color(red: 1.000, green: 0.714, blue: 0.149).opacity(0.20)
        static let testBadgeFg   = Color(red: 1.000, green: 0.839, blue: 0.510)
    }

    // MARK: - Type Scale

    enum TypeScale {
        static let largeTitle = Font.system(size: 34, weight: .bold,   design: .rounded)
        static let title      = Font.system(size: 28, weight: .bold,   design: .rounded)
        static let title2     = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let headline   = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body       = Font.system(size: 17, weight: .regular, design: .rounded)
        static let callout    = Font.system(size: 16, weight: .medium,  design: .rounded)
        static let caption    = Font.system(size: 13, weight: .regular, design: .rounded)
        static let captionBold = Font.system(size: 13, weight: .semibold, design: .rounded)
        static let money      = Font.system(size: 20, weight: .bold,   design: .monospaced)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 24
        static let xl:  CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum Radius {
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 12
        static let lg:  CGFloat = 16
        static let pill: CGFloat = 100
    }
}
