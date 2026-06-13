import SwiftUI

// MARK: - MoneyLabel (D-01, D-02, D-03, SAFE-01, SAFE-02, SAFE-03)
//
// THE ONLY SANCTIONED WAY to render a £ amount in LockedIN.
// Displaying money without the TEST marker is structurally impossible:
// every MoneyLabel always emits both the formatted figure AND the marker.
//
// No other view may call `formatPence` directly to render a £ figure.

/// Renders a `Pence` amount as `£X.XX` with the inline TEST marker.
/// Use `compact: true` for tight spaces (shows a "TEST" pill); the full statement
/// "TEST MODE — NO REAL MONEY WILL MOVE" is always reachable on any money screen.
struct MoneyLabel: View {
    let amount: Pence
    var compact: Bool = false

    init(_ amount: Pence, compact: Bool = false) {
        self.amount = amount
        self.compact = compact
    }

    var body: some View {
        if compact {
            compactLayout
        } else {
            fullLayout
        }
    }

    // MARK: - Full Layout (default)

    private var fullLayout: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(formatPence(amount))
                .font(Theme.TypeScale.money)
                .foregroundStyle(Theme.Colour.moneyGreen)

            // The TEST MODE marker — ALWAYS rendered.
            // Gated on ENABLE_REAL_MONEY_STAKES being false (SAFE-02, FND-05):
            // because the flag is false, this block always executes and the
            // marker is always shown. If the flag were ever flipped true in
            // a real-money build, the marker would be suppressed — this is
            // how the flag is HONOURED at its boundary, not just declared.
            if !FeatureFlags.ENABLE_REAL_MONEY_STAKES {
                testModeStatement
            }
        }
    }

    // MARK: - Compact Layout

    private var compactLayout: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text(formatPence(amount))
                .font(Theme.TypeScale.headline)
                .foregroundStyle(Theme.Colour.moneyGreen)

            // Compact "TEST" pill — always rendered when flag is false (SAFE-02).
            if !FeatureFlags.ENABLE_REAL_MONEY_STAKES {
                testPill
            }
        }
    }

    // MARK: - TEST MODE Components

    /// Compact inline "TEST" pill for tight layouts.
    private var testPill: some View {
        Text("TEST")
            .font(Theme.TypeScale.captionBold)
            .foregroundStyle(Theme.Colour.testBadgeFg)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 2)
            .background(Theme.Colour.testBadgeBg)
            .clipShape(Capsule())
    }

    /// Full "TEST MODE — NO REAL MONEY WILL MOVE" statement.
    private var testModeStatement: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.Colour.testBadgeFg)
            Text("TEST MODE — NO REAL MONEY WILL MOVE")
                .font(Theme.TypeScale.caption)
                .foregroundStyle(Theme.Colour.testBadgeFg)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Theme.Colour.testBadgeBg)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
    }
}

// MARK: - Previews

#Preview("Full layout") {
    VStack(spacing: Theme.Spacing.lg) {
        MoneyLabel(500)
        MoneyLabel(2000)
        MoneyLabel(50)
        MoneyLabel(1500)
    }
    .padding()
    .background(Theme.Colour.background)
}

#Preview("Compact layout") {
    VStack(spacing: Theme.Spacing.md) {
        MoneyLabel(500, compact: true)
        MoneyLabel(2000, compact: true)
        MoneyLabel(50, compact: true)
    }
    .padding()
    .background(Theme.Colour.surface)
}
