import SwiftUI

// MARK: - CharacterCustomizerView — the avatar creator / wardrobe (mockup 02 layout)
//
// A live-preview character editor: a category icon rail down the left (skin, hair,
// hair colour, face, top, bottoms, shoes, outfit colour, accessory), a large preview
// on a pedestal, and a swatch grid for the active category. Randomise (dice) rolls a
// fresh look from free + owned options. Premium cosmetics (headphones, cap, beanie,
// pink/auburn hair, afro) cost LockedIN coins — tapping a locked option buys it if
// affordable (cosmetic-only, never pay-to-win).
//
// Reusable: an onboarding beat (onBack returns to the gallery) and "Edit character"
// from the world (onBack nil → dismisses). Naming lives at the reveal beat / profile,
// not here — `initialName` passes through onSave unchanged.

struct CharacterCustomizerView: View {

    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss

    let initial: CharacterAppearance
    var initialName: String = ""
    var onBack: (() -> Void)? = nil
    var onSave: (CharacterAppearance, String) -> Void

    @State private var appearance: CharacterAppearance
    @State private var category: Category = .hair
    @State private var toast: String?

    init(initial: CharacterAppearance,
         initialName: String = "",
         onBack: (() -> Void)? = nil,
         onSave: @escaping (CharacterAppearance, String) -> Void) {
        self.initial = initial
        self.initialName = initialName
        self.onBack = onBack
        self.onSave = onSave
        _appearance = State(initialValue: initial)
    }

    private var coins: Int { appStore.world.state.progression.coins }

    // MARK: - Categories

    private enum Category: String, CaseIterable, Identifiable {
        case skin, hair, hairColour, face, top, bottoms, shoes, accent, accessory
        var id: String { rawValue }

        var icon: PixelIcon {
            switch self {
            case .skin:       return .hand
            case .hair:       return .comb
            case .hairColour: return .droplet
            case .face:       return .smiley
            case .top:        return .shirt
            case .bottoms:    return .trousers
            case .shoes:      return .shoe
            case .accent:     return .palette
            case .accessory:  return .cap
            }
        }

        var title: String {
            switch self {
            case .skin:       return "Skin"
            case .hair:       return "Hair"
            case .hairColour: return "Hair colour"
            case .face:       return "Face"
            case .top:        return "Top"
            case .bottoms:    return "Bottoms"
            case .shoes:      return "Shoes"
            case .accent:     return "Outfit colour"
            case .accessory:  return "Accessory"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Colour.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                HStack(alignment: .top, spacing: 0) {
                    categoryRail
                        .padding(.leading, Theme.Spacing.sm)

                    VStack(spacing: Theme.Spacing.md) {
                        preview
                        swatchArea
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
                .padding(.top, Theme.Spacing.sm)

                Spacer(minLength: 0)
            }
            .padding(.bottom, 88)

            saveBar
            if let toast { toastView(toast) }
        }
        .statusBarHidden(true)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Button {
                if let onBack { onBack() } else { dismiss() }
            } label: {
                Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.Colour.textSecondary)
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("Back")

            Spacer()

            Text("Customise").font(Theme.TypeScale.headline).foregroundStyle(Theme.Colour.textPrimary)

            Spacer()

            // Coins chip
            HStack(spacing: 4) {
                PixelIconView(icon: .coin, size: 13, tint: Theme.Colour.accent)
                Text("\(coins)").font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.textPrimary).monospacedDigit()
            }
            .padding(.horizontal, Theme.Spacing.sm).padding(.vertical, 5)
            .background(PixelPanelShape(unit: 2).fill(Theme.Colour.surface))
            .overlay(PixelPanelShape(unit: 2).stroke(Theme.Colour.cardBorder, lineWidth: 1.5))

            // Randomise
            Button { randomise() } label: {
                PixelIconView(icon: .dice, size: 20, tint: Theme.Colour.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(PixelPanelShape(unit: 2).fill(Theme.Colour.surface))
                    .overlay(PixelPanelShape(unit: 2).stroke(Theme.Colour.cardBorder, lineWidth: 1.5))
            }
            .accessibilityLabel("Randomise appearance")
        }
        .padding(.horizontal, Theme.Spacing.lg).padding(.top, Theme.Spacing.lg).padding(.bottom, Theme.Spacing.sm)
    }

    // MARK: - Category rail

    private var categoryRail: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(Category.allCases) { c in
                let selected = category == c
                Button {
                    withAnimation(.easeInOut(duration: 0.12)) { category = c }
                } label: {
                    PixelIconView(icon: c.icon, size: 20,
                                  tint: selected ? Theme.Colour.textOnAccent : Theme.Colour.textSecondary)
                        .frame(width: 42, height: 42)
                        .background(PixelPanelShape(unit: 3)
                            .fill(selected ? Theme.Colour.accent : Theme.Colour.surface))
                        .overlay(PixelPanelShape(unit: 3)
                            .stroke(selected ? Theme.Colour.appShell : Theme.Colour.cardBorder,
                                    lineWidth: selected ? 2 : 1.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(c.title)
            }
        }
    }

    // MARK: - Preview

    private var preview: some View {
        ZStack {
            PixelPanelShape(unit: 5)
                .fill(LinearGradient(colors: [Theme.Colour.surfaceMid, Theme.Colour.surface],
                                     startPoint: .top, endPoint: .bottom))
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                ZStack {
                    Ellipse()
                        .fill(Theme.Colour.cardBorder.opacity(0.55))
                        .frame(width: 120, height: 26)
                        .offset(y: 66)
                    PixelAvatarView(appearance: appearance, status: .idle, size: 140)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, Theme.Spacing.sm)
        }
        .overlay(PixelPanelShape(unit: 5).stroke(Theme.Colour.cardBorder, lineWidth: 1.5))
        .frame(height: 220)
    }

    // MARK: - Swatch area

    private let swatchColumns = [GridItem(.adaptive(minimum: 58, maximum: 72), spacing: Theme.Spacing.sm)]

    private var swatchArea: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(category.title)
                .font(Theme.TypeScale.headline)
                .foregroundStyle(Theme.Colour.textPrimary)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: swatchColumns, spacing: Theme.Spacing.sm) {
                    swatches
                }
                .padding(Theme.Spacing.sm)
            }
            .background(PixelPanelShape(unit: 4).fill(Theme.Colour.surfaceMid.opacity(0.6)))
            .overlay(PixelPanelShape(unit: 4).stroke(Theme.Colour.cardBorder, lineWidth: 1.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var swatches: some View {
        switch category {
        case .skin:
            ForEach(SkinTone.allCases, id: \.self) { t in
                swatchChip(colour: t.colour, selected: appearance.skinTone == t,
                           id: CosmeticCatalog.id(skin: t), label: t.displayName) { appearance.skinTone = t }
            }
        case .hair:
            ForEach(HairStyle.allCases, id: \.self) { h in
                var a = appearance; a.hairStyle = h
                return avatarChip(preview: a, selected: appearance.hairStyle == h,
                                  id: CosmeticCatalog.id(hairStyle: h), label: h.displayName) { appearance.hairStyle = h }
            }
        case .hairColour:
            ForEach(HairColour.allCases, id: \.self) { c in
                swatchChip(colour: c.colour, selected: appearance.hairColour == c,
                           id: CosmeticCatalog.id(hairColour: c), label: c.displayName) { appearance.hairColour = c }
            }
        case .face:
            ForEach(FaceStyle.allCases, id: \.self) { f in
                var a = appearance; a.faceStyle = f
                return avatarChip(preview: a, selected: appearance.faceStyle == f,
                                  id: nil, label: f.displayName) { appearance.faceStyle = f }
            }
        case .top:
            ForEach(TopStyle.allCases, id: \.self) { t in
                var a = appearance; a.topStyle = t
                return avatarChip(preview: a, selected: appearance.topStyle == t,
                                  id: nil, label: t.displayName) { appearance.topStyle = t }
            }
        case .bottoms:
            ForEach(BottomStyle.allCases, id: \.self) { b in
                var a = appearance; a.bottomStyle = b
                return avatarChip(preview: a, selected: appearance.bottomStyle == b,
                                  id: nil, label: b.displayName) { appearance.bottomStyle = b }
            }
        case .shoes:
            ForEach(ShoeStyle.allCases, id: \.self) { s in
                var a = appearance; a.shoeStyle = s
                return avatarChip(preview: a, selected: appearance.shoeStyle == s,
                                  id: nil, label: s.displayName) { appearance.shoeStyle = s }
            }
        case .accent:
            ForEach(AccentColour.allCases, id: \.self) { a in
                swatchChip(colour: a.colour, selected: appearance.accentColour == a,
                           id: CosmeticCatalog.id(accent: a), label: a.displayName) { appearance.accentColour = a }
            }
        case .accessory:
            ForEach(Accessory.allCases, id: \.self) { acc in
                var a = appearance; a.accessory = acc
                return avatarChip(preview: a, selected: appearance.accessory == acc,
                                  id: CosmeticCatalog.id(accessory: acc), label: acc.displayName) { appearance.accessory = acc }
            }
        }
    }

    // MARK: - Chips

    private func swatchChip(colour: Color, selected: Bool, id: String?, label: String,
                            apply: @escaping () -> Void) -> some View {
        let locked = id.map { !appStore.world.owns($0) } ?? false
        return Button { choose(id, apply) } label: {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(colour)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().strokeBorder(selected ? Theme.Colour.accent : Theme.Colour.cardBorder,
                                                   lineWidth: selected ? 3 : 1.5))
                    .opacity(locked ? 0.5 : 1)
                    .frame(width: 56, height: 56)
                if locked, let id { priceTag(CosmeticCatalog.cost(for: id)) }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label)\(selected ? ", selected" : "")")
    }

    private func avatarChip(preview: CharacterAppearance, selected: Bool, id: String?, label: String,
                            apply: @escaping () -> Void) -> some View {
        let locked = id.map { !appStore.world.owns($0) } ?? false
        return Button { choose(id, apply) } label: {
            ZStack(alignment: .topTrailing) {
                PixelAvatarView(appearance: preview, status: .idle, size: 48)
                    .frame(width: 56, height: 56)
                    .background(PixelPanelShape(unit: 3).fill(Theme.Colour.surface))
                    .overlay(PixelPanelShape(unit: 3)
                        .stroke(selected ? Theme.Colour.accent : Theme.Colour.cardBorder,
                                lineWidth: selected ? 3 : 1.5))
                    .opacity(locked ? 0.55 : 1)
                if locked, let id { priceTag(CosmeticCatalog.cost(for: id)) }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label)\(selected ? ", selected" : "")")
    }

    private func priceTag(_ cost: Int) -> some View {
        HStack(spacing: 2) {
            PixelIconView(icon: .coin, size: 8, tint: Theme.Colour.textOnAccent)
            Text("\(cost)").font(.system(size: 9, weight: .heavy)).foregroundStyle(Theme.Colour.textOnAccent)
        }
        .padding(.horizontal, 4).padding(.vertical, 2)
        .background(PixelPanelShape(unit: 1).fill(Theme.Colour.accent))
        .offset(x: 4, y: -4)
    }

    // MARK: - Save bar

    private var saveBar: some View {
        Button("Save avatar") { save() }
            .buttonStyle(PixelButtonStyle(kind: .gold))
            .padding(.horizontal, Theme.Spacing.lg).padding(.bottom, Theme.Spacing.lg)
    }

    private func toastView(_ text: String) -> some View {
        Text(text)
            .font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.buttonText)
            .padding(.horizontal, Theme.Spacing.md).padding(.vertical, Theme.Spacing.sm)
            .background(PixelPanelShape(unit: 2).fill(Theme.Colour.buttonFill))
            .padding(.bottom, 96)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions

    /// Select a cosmetic — free items (nil id) apply immediately; premium ones buy if affordable.
    private func choose(_ id: String?, _ apply: @escaping () -> Void) {
        guard let id else {
            withAnimation(.easeInOut(duration: 0.15)) { apply() }
            return
        }
        if appStore.world.owns(id) {
            withAnimation(.easeInOut(duration: 0.15)) { apply() }
        } else if appStore.world.purchase(id) {
            withAnimation(.easeInOut(duration: 0.15)) { apply() }
            flash("Unlocked! ✨")
        } else {
            flash("Need \(CosmeticCatalog.cost(for: id)) coins")
        }
    }

    private func randomise() {
        var rng = SystemRandomNumberGenerator()
        let rolled = CharacterAppearance.randomised(owned: appStore.world.state.ownedCosmetics,
                                                    using: &rng)
        withAnimation(.easeInOut(duration: 0.2)) { appearance = rolled }
    }

    private func flash(_ message: String) {
        withAnimation { toast = message }
        Task {
            try? await Task.sleep(for: .seconds(1.4))
            withAnimation { toast = nil }
        }
    }

    private func save() {
        onSave(appearance, initialName.trimmingCharacters(in: .whitespaces))
        if onBack == nil { dismiss() }
    }
}

#Preview("Customizer") {
    CharacterCustomizerView(initial: .default, initialName: "You", onSave: { _, _ in })
        .environment(AppStore())
}
