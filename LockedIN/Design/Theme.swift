import SwiftUI

// MARK: - Theme (D-04, D-05, D-06)
//
// Foundational design tokens for LockedIN.
// Playful-but-honest: warm amber study-room energy, honest controls, no dark patterns.
// Keep lightweight — this is a 5h build, not a full design system (D-06).

enum Theme {

    // MARK: - Colour Palette

    enum Colour {
        // Backgrounds — warm CREAM "Version B" direction (mockup-matched).
        // Modern cream product layer that frames the pixel game layer.
        static let background = Color(red: 0.957, green: 0.922, blue: 0.847)   // #F4EBD8 warm cream parchment
        static let surface    = Color(red: 0.984, green: 0.961, blue: 0.910)   // #FBF5E8 lighter cream card
        static let surfaceMid = Color(red: 0.929, green: 0.886, blue: 0.796)   // #EDE2CB deeper cream / nested

        // App shell + dark controls — charcoal near-black frame & primary pill buttons
        static let appShell   = Color(red: 0.122, green: 0.106, blue: 0.086)   // #1F1B16 charcoal shell/border
        static let buttonFill = Color(red: 0.137, green: 0.118, blue: 0.094)   // #231E18 dark pill button
        static let buttonText = Color(red: 0.965, green: 0.937, blue: 0.871)   // #F6EFDE cream text on dark pill
        static let cardBorder = Color(red: 0.835, green: 0.769, blue: 0.643)   // #D5C4A4 soft tan card border
        static let sparkle    = Color(red: 1.000, green: 0.839, blue: 0.510)   // #FFD682 reveal-moment glow

        // Accent — warm amber/gold (study lamp, reveal/CTA energy)
        static let accent     = Color(red: 1.000, green: 0.714, blue: 0.149)   // #FFB626 amber gold
        static let accentSoft = Color(red: 1.000, green: 0.839, blue: 0.510)   // #FFD682 soft amber

        // Semantic — commitment money (not coins; the two economies must stay distinct)
        static let moneyGreen = Color(red: 0.157, green: 0.620, blue: 0.345)   // #289E58 return/success (darker for cream)
        static let forfeitRed = Color(red: 0.804, green: 0.224, blue: 0.224)   // #CD3939 forfeit/warning (darker for cream)

        // Text — dark on cream
        static let textPrimary   = Color(red: 0.169, green: 0.149, blue: 0.125) // #2B2620 charcoal ink
        static let textSecondary = Color(red: 0.478, green: 0.431, blue: 0.361) // #7A6E5C muted warm brown
        static let textOnAccent  = Color(red: 0.169, green: 0.149, blue: 0.125) // dark text on gold/cream

        // TEST MODE pill — dark amber on cream, never hiding what it is
        static let testBadgeBg   = Color(red: 1.000, green: 0.714, blue: 0.149).opacity(0.28)
        static let testBadgeFg   = Color(red: 0.420, green: 0.302, blue: 0.071) // #6B4D12 dark amber ink

        // Skin tones (avatar layer fills, D-21b)
        static let skinLight  = Color(red: 0.992, green: 0.859, blue: 0.706)   // #FDDBB4 warm pale
        static let skinMedium = Color(red: 0.831, green: 0.584, blue: 0.416)   // #D4956A warm golden
        static let skinDark   = Color(red: 0.553, green: 0.333, blue: 0.141)   // #8D5524 deep warm brown
        static let skinDeep   = Color(red: 0.290, green: 0.161, blue: 0.071)   // #4A2912 richest tone

        // Hair colours (avatar layer fills, D-21b)
        static let hairBlonde = Color(red: 0.910, green: 0.788, blue: 0.478)   // #E8C97A warm straw
        static let hairBrown  = Color(red: 0.420, green: 0.227, blue: 0.165)   // #6B3A2A chestnut
        static let hairBlack  = Color(red: 0.102, green: 0.071, blue: 0.063)   // #1A1210 near-black warm
        static let hairSilver = Color(red: 0.627, green: 0.627, blue: 0.627)   // #A0A0A0 cool grey-silver

        // Avatar accent colours (outfit tints — amber reuses Theme.Colour.accent)
        static let accentTeal     = Color(red: 0.302, green: 0.722, blue: 0.643) // #4DB8A4 study-room teal
        static let accentRose     = Color(red: 0.878, green: 0.420, blue: 0.545) // #E06B8B warm rose
        static let accentLavender = Color(red: 0.608, green: 0.494, blue: 0.784) // #9B7EC8 muted lavender

        // Room furniture colours (D-28, ONB-05)
        static let plantGreen  = Color(red: 0.290, green: 0.486, blue: 0.349)   // #4A7C59 dark olive green
        static let windowSlate = Color(red: 0.165, green: 0.227, blue: 0.322)   // #2A3A52 night window
    }

    // MARK: - Type Scale

    enum TypeScale {
        static let largeTitle = Font.system(size: 34, weight: .bold,   design: .rounded)
        static let title      = Font.system(size: 28, weight: .bold,   design: .rounded)
        static let title2     = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let headline   = Font.system(size: 17, weight: .bold,     design: .rounded)
        static let body       = Font.system(size: 17, weight: .regular, design: .rounded)
        static let callout    = Font.system(size: 16, weight: .medium,  design: .rounded)
        static let caption    = Font.system(size: 13, weight: .regular, design: .rounded)
        static let captionBold = Font.system(size: 13, weight: .bold,   design: .rounded)
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
