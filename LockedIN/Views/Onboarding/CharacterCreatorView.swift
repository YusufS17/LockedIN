import SwiftUI

// MARK: - CharacterCreatorView (D-22, ONB-02) — Beat 2 of 3
//
// Mix-and-match character creator with:
//   - Left vertical category rail (skin / hair / outfit / accent)
//   - Large live AvatarView preview (120pt) on a soft oval shadow platform
//   - Colour swatch grid for the active category (+ ◀▶ cycling for style options)
//   - Dark charcoal "That's me" pill CTA at the bottom
//   - "Skip intro" top-right text button
//   - 3-dot progress indicator (dot 2 active)
//
// Design target: mockup 02-character-customiser.png (cream card, category rail,
//   avatar on oval platform, swatch palette, dark NEXT pill). Version B cream/charcoal/gold.
//
// Init: CharacterCreatorView(onContinue: (CharacterAppearance) -> Void, onSkip: () -> Void)
// Does NOT write to AppStore — OnboardingView commits on completion (D-22).

// MARK: - Creator Category

/// The four customisable dimensions, used to drive the left category rail.
private enum CreatorCategory: CaseIterable {
    case skin, hair, outfit, accent

    var label: String {
        switch self {
        case .skin:   return "Skin"
        case .hair:   return "Hair"
        case .outfit: return "Outfit"
        case .accent: return "Accent"
        }
    }

    var symbolName: String {
        switch self {
        case .skin:   return "face.smiling"
        case .hair:   return "scissors"
        case .outfit: return "tshirt"
        case .accent: return "paintpalette"
        }
    }
}

// MARK: - CharacterCreatorView

struct CharacterCreatorView: View {

    // MARK: - Init

    let onContinue: (CharacterAppearance) -> Void
    let onSkip: () -> Void

    // MARK: - State

    @State private var localAppearance: CharacterAppearance = .default
    @State private var activeCategory: CreatorCategory = .skin

    // MARK: - Body

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: skip button aligned right
                topBar

                // Main content: category rail + avatar card
                Spacer(minLength: Theme.Spacing.sm)
                mainCard
                Spacer(minLength: Theme.Spacing.sm)

                // Progress dots + CTA
                bottomSection
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xxl)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Spacer()
            Button("Skip intro", action: onSkip)
                .font(Theme.TypeScale.captionBold)
                .foregroundStyle(Theme.Colour.textSecondary)
                .accessibilityLabel("Skip onboarding")
        }
    }

    // MARK: - Main Card

    private var mainCard: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left vertical category rail
            categoryRail

            // Right content: avatar preview + palette
            VStack(spacing: Theme.Spacing.md) {
                // Heading
                Text("Create your character")
                    .font(Theme.TypeScale.title)
                    .foregroundStyle(Theme.Colour.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, Theme.Spacing.md)

                // Avatar preview on oval shadow platform
                avatarPreviewSection

                // Palette / selector for active category
                categoryPaletteSection
                    .padding(.bottom, Theme.Spacing.md)
            }
            .frame(maxWidth: .infinity)
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Theme.Colour.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .strokeBorder(Theme.Colour.cardBorder, lineWidth: 1)
                )
        )
    }

    // MARK: - Category Rail

    private var categoryRail: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ForEach(CreatorCategory.allCases, id: \.label) { category in
                categoryRailButton(category)
            }
        }
        .padding(.vertical, Theme.Spacing.md)
        .padding(.horizontal, Theme.Spacing.sm)
    }

    private func categoryRailButton(_ category: CreatorCategory) -> some View {
        let isActive = activeCategory == category
        return Button {
            activeCategory = category
        } label: {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: category.symbolName)
                    .font(.system(size: 18, weight: isActive ? .bold : .regular))
                    .foregroundStyle(isActive ? Theme.Colour.textPrimary : Theme.Colour.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.sm)
                            .fill(isActive ? Theme.Colour.surfaceMid : Color.clear)
                    )
            }
        }
        .accessibilityLabel(category.label)
    }

    // MARK: - Avatar Preview

    private var avatarPreviewSection: some View {
        ZStack {
            // Oval shadow/platform (soft glow beneath avatar per mockup)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colour.sparkle.opacity(0.35),
                            Theme.Colour.sparkle.opacity(0.10),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 60
                    )
                )
                .frame(width: 130, height: 44)
                .offset(y: 50)

            // Live avatar preview — updates instantly on every selector change
            AvatarView(appearance: localAppearance, status: .idle, size: 120)
        }
        .frame(height: 150)
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Category Palette / Selector

    @ViewBuilder
    private var categoryPaletteSection: some View {
        switch activeCategory {
        case .skin:
            skinSelectorSection
        case .hair:
            hairSelectorSection
        case .outfit:
            outfitSelectorSection
        case .accent:
            accentSelectorSection
        }
    }

    // MARK: Skin Selector — swatch grid

    private var skinSelectorSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Skin")
                .font(Theme.TypeScale.headline)
                .foregroundStyle(Theme.Colour.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            swatchGrid(
                options: SkinTone.allCases,
                selectedOption: localAppearance.skinTone,
                colour: { $0.colour },
                label: { $0.displayName },
                onSelect: { localAppearance.skinTone = $0 }
            )

            // ◀▶ stepper row for accessibility + wrap-around cycling
            stepperRow(
                label: "Skin",
                displayName: localAppearance.skinTone.displayName,
                swatch: localAppearance.skinTone.colour,
                previous: { localAppearance.skinTone = previous(localAppearance.skinTone) },
                next: { localAppearance.skinTone = next(localAppearance.skinTone) }
            )
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: Hair Selector — style ◀▶ + colour swatch grid

    private var hairSelectorSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Hair")
                .font(Theme.TypeScale.headline)
                .foregroundStyle(Theme.Colour.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Style cycling row
            stepperRow(
                label: "Hair",
                displayName: localAppearance.hairStyle.displayName,
                swatch: nil,
                previous: { localAppearance.hairStyle = previous(localAppearance.hairStyle) },
                next: { localAppearance.hairStyle = next(localAppearance.hairStyle) }
            )

            // Colour swatches
            swatchGrid(
                options: HairColour.allCases,
                selectedOption: localAppearance.hairColour,
                colour: { $0.colour },
                label: { $0.displayName },
                onSelect: { localAppearance.hairColour = $0 }
            )
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: Outfit Selector — style ◀▶

    private var outfitSelectorSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Outfit")
                .font(Theme.TypeScale.headline)
                .foregroundStyle(Theme.Colour.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            stepperRow(
                label: "Outfit",
                displayName: localAppearance.outfitStyle.displayName,
                swatch: nil,
                previous: { localAppearance.outfitStyle = previous(localAppearance.outfitStyle) },
                next: { localAppearance.outfitStyle = next(localAppearance.outfitStyle) }
            )

            // Show current outfit colour swatch as a hint
            HStack {
                Text("Colour")
                    .font(Theme.TypeScale.caption)
                    .foregroundStyle(Theme.Colour.textSecondary)
                Circle()
                    .fill(localAppearance.accentColour.colour)
                    .frame(width: 16, height: 16)
                Text("(set in Accent)")
                    .font(Theme.TypeScale.caption)
                    .foregroundStyle(Theme.Colour.textSecondary)
                Spacer()
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: Accent Selector — swatch grid

    private var accentSelectorSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Accent")
                .font(Theme.TypeScale.headline)
                .foregroundStyle(Theme.Colour.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            swatchGrid(
                options: AccentColour.allCases,
                selectedOption: localAppearance.accentColour,
                colour: { $0.colour },
                label: { $0.displayName },
                onSelect: { localAppearance.accentColour = $0 }
            )

            stepperRow(
                label: "Accent",
                displayName: localAppearance.accentColour.displayName,
                swatch: localAppearance.accentColour.colour,
                previous: { localAppearance.accentColour = previous(localAppearance.accentColour) },
                next: { localAppearance.accentColour = next(localAppearance.accentColour) }
            )
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Swatch Grid Helper

    /// Generic colour-swatch grid — 4 swatches in a row, tappable, with selection ring.
    private func swatchGrid<Option: CaseIterable & Equatable>(
        options: Option.AllCases,
        selectedOption: Option,
        colour: @escaping (Option) -> Color,
        label: @escaping (Option) -> String,
        onSelect: @escaping (Option) -> Void
    ) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                Button {
                    onSelect(option)
                } label: {
                    ZStack {
                        Circle()
                            .fill(colour(option))
                            .frame(width: 36, height: 36)
                        if option == selectedOption {
                            Circle()
                                .strokeBorder(Theme.Colour.textPrimary, lineWidth: 2.5)
                                .frame(width: 40, height: 40)
                        }
                    }
                }
                .accessibilityLabel(label(option))
            }
            Spacer()
        }
    }

    // MARK: - Stepper Row Helper

    /// Generic ◀▶ cycling stepper row with 44×44pt touch targets and accessibility labels.
    /// Used for style options (hair style, outfit) and as an additional cycling control
    /// alongside swatches for colour options (skin, accent).
    private func stepperRow(
        label: String,
        displayName: String,
        swatch: Color?,
        previous: @escaping () -> Void,
        next: @escaping () -> Void
    ) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            // Previous button — 44×44pt minimum touch target (iOS HIG)
            Button(action: previous) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colour.textPrimary)
            }
            .frame(width: 44, height: 44)
            .accessibilityLabel("Previous \(label)")

            // Value label with optional swatch
            HStack(spacing: Theme.Spacing.xs) {
                if let swatch {
                    Circle()
                        .fill(swatch)
                        .frame(width: 16, height: 16)
                }
                Text(displayName)
                    .font(Theme.TypeScale.body)
                    .foregroundStyle(Theme.Colour.textPrimary)
                    .frame(minWidth: 80, alignment: .center)
            }
            .frame(maxWidth: .infinity)

            // Next button — 44×44pt minimum touch target (iOS HIG)
            Button(action: next) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colour.textPrimary)
            }
            .frame(width: 44, height: 44)
            .accessibilityLabel("Next \(label)")
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                .fill(Theme.Colour.surfaceMid)
        )
    }

    // MARK: - Cycling Helpers

    /// Returns the previous case in a CaseIterable enum, wrapping from first to last.
    private func previous<T: CaseIterable & Equatable>(_ current: T) -> T {
        let allCases = Array(T.allCases)
        guard let idx = allCases.firstIndex(of: current) else { return current }
        let prevIdx = idx == allCases.startIndex ? allCases.index(before: allCases.endIndex) : allCases.index(before: idx)
        return allCases[prevIdx]
    }

    /// Returns the next case in a CaseIterable enum, wrapping from last to first.
    private func next<T: CaseIterable & Equatable>(_ current: T) -> T {
        let allCases = Array(T.allCases)
        guard let idx = allCases.firstIndex(of: current) else { return current }
        let nextIdx = allCases.index(after: idx)
        return nextIdx == allCases.endIndex ? allCases[allCases.startIndex] : allCases[nextIdx]
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            progressDots(active: 1)

            // "That's me" — dark charcoal pill button (Version B design language)
            // Always enabled: localAppearance is always valid (pre-loaded with .default)
            Button {
                onContinue(localAppearance)
            } label: {
                Text("That's me")
                    .font(Theme.TypeScale.headline)
                    .foregroundStyle(Theme.Colour.buttonText)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colour.buttonFill)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
            }
        }
    }

    // MARK: - Progress Dots

    /// 3-dot progress indicator. Active dot: 8×8pt amber circle. Inactive: 4×4pt textSecondary@40%.
    private func progressDots(active: Int) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(i == active ? Theme.Colour.accent : Theme.Colour.textSecondary.opacity(0.4))
                    .frame(
                        width:  i == active ? 8 : 4,
                        height: i == active ? 8 : 4
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview("Character Creator") {
    let store = AppStore()
    return CharacterCreatorView(
        onContinue: { _ in },
        onSkip: {}
    )
    .environment(store)
}

#Preview("Character Creator — all accent colours") {
    let store = AppStore()
    return CharacterCreatorView(
        onContinue: { _ in },
        onSkip: {}
    )
    .environment(store)
}
