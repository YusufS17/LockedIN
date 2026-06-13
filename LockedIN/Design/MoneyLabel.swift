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

            // IN-01 fix: the else branch renders an explicit real-money badge rather
            // than nothing. This ensures that flipping ENABLE_REAL_MONEY_STAKES to
            // true never silently removes all money indicators — a distinct "LIVE"
            // badge is shown instead, preserving the safety invariant that a £ figure
            // is never rendered without a visible qualifier.
            if !FeatureFlags.ENABLE_REAL_MONEY_STAKES {
                testModeStatement
            } else {
                realMoneyBadge
            }
        }
    }

    // MARK: - Compact Layout

    private var compactLayout: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text(formatPence(amount))
                .font(Theme.TypeScale.headline)
                .foregroundStyle(Theme.Colour.moneyGreen)

            // IN-01 fix: show either test pill or real-money pill; never neither.
            if !FeatureFlags.ENABLE_REAL_MONEY_STAKES {
                testPill
            } else {
                realMoneyPill
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

    // MARK: - REAL MONEY Components (IN-01)
    // Rendered when ENABLE_REAL_MONEY_STAKES is true so £ figures are never
    // displayed without a visible qualifier — even in a live-money build.

    /// Compact inline "LIVE" pill for real-money builds.
    private var realMoneyPill: some View {
        Text("LIVE")
            .font(Theme.TypeScale.captionBold)
            .foregroundStyle(Theme.Colour.textOnAccent)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 2)
            .background(Theme.Colour.forfeitRed)
            .clipShape(Capsule())
    }

    /// Full "REAL MONEY — STAKES ACTIVE" statement for real-money builds.
    private var realMoneyBadge: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.Colour.textOnAccent)
            Text("REAL MONEY — STAKES ACTIVE")
                .font(Theme.TypeScale.caption)
                .foregroundStyle(Theme.Colour.textOnAccent)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Theme.Colour.forfeitRed)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
    }

    // MARK: - TEST MODE Components

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
