import SwiftUI

// MARK: - CharacterCustomizerView — the avatar creator / wardrobe
//
// A live-preview character editor: skin, hair style, hair colour, outfit, accent, and
// accessories, plus a name. Most options are free; premium cosmetics (headphones, cap,
// beanie, pink/auburn hair, afro) cost LockedIN coins — tapping a locked option buys it
// if affordable (cosmetic-only, never pay-to-win). Saves to the user's avatar everywhere.
//
// Reusable: onboarding seeds it from a picked character; "Edit character" seeds it from
// the current avatar.

struct CharacterCustomizerView: View {

    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss

    let initial: CharacterAppearance
    var initialName: String = ""
    var onSave: (CharacterAppearance, String) -> Void

    @State private var appearance: CharacterAppearance
    @State private var name: String
    @State private var toast: String?

    init(initial: CharacterAppearance,
         initialName: String = "",
         onSave: @escaping (CharacterAppearance, String) -> Void) {
        self.initial = initial
        self.initialName = initialName
        self.onSave = onSave
        _appearance = State(initialValue: initial)
        _name = State(initialValue: initialName)
    }

    private var coins: Int { appStore.world.state.progression.coins }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Colour.background.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        preview
                        skinSection
                        hairStyleSection
                        hairColourSection
                        outfitSection
                        accentSection
                        accessorySection
                    }
                    .padding(Theme.Spacing.lg)
                    .padding(.bottom, 90)
                }
            }
            saveBar
            if let toast { toastView(toast) }
        }
        .statusBarHidden(true)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.Colour.textSecondary)
            }
            Spacer()
            Text("Customise").font(Theme.TypeScale.headline).foregroundStyle(Theme.Colour.textPrimary)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "circle.fill").font(.system(size: 10)).foregroundStyle(Theme.Colour.accent)
                Text("\(coins)").font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.textPrimary).monospacedDigit()
            }
            .padding(.horizontal, Theme.Spacing.sm).padding(.vertical, 5)
            .background(Capsule().fill(Theme.Colour.surface))
            .overlay(Capsule().strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
        }
        .padding(.horizontal, Theme.Spacing.lg).padding(.top, Theme.Spacing.lg).padding(.bottom, Theme.Spacing.sm)
    }

    // MARK: - Preview + name

    private var preview: some View {
        VStack(spacing: Theme.Spacing.md) {
            PixelAvatarView(appearance: appearance, status: .idle, size: 150)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .fill(LinearGradient(colors: [Theme.Colour.surfaceMid, Theme.Colour.surface],
                                             startPoint: .top, endPoint: .bottom))
                )
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))

            HStack(spacing: Theme.Spacing.sm) {
                Text("Name").font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.textSecondary)
                TextField("Enter a name…", text: $name)
                    .font(Theme.TypeScale.headline).foregroundStyle(Theme.Colour.textPrimary)
                    .textFieldStyle(.plain)
                    .onChange(of: name) { _, new in if new.count > 24 { name = String(new.prefix(24)) } }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colour.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
        }
    }

    // MARK: - Sections

    private var skinSection: some View {
        section("SKIN") {
            ForEach(SkinTone.allCases, id: \.self) { t in
                swatchChip(colour: t.colour, selected: appearance.skinTone == t,
                           id: CosmeticCatalog.id(skin: t)) { appearance.skinTone = t }
            }
        }
    }

    private var hairStyleSection: some View {
        section("HAIR") {
            ForEach(HairStyle.allCases, id: \.self) { h in
                var a = appearance; a.hairStyle = h
                return avatarChip(preview: a, selected: appearance.hairStyle == h,
                                  id: CosmeticCatalog.id(hairStyle: h)) { appearance.hairStyle = h }
            }
        }
    }

    private var hairColourSection: some View {
        section("HAIR COLOUR") {
            ForEach(HairColour.allCases, id: \.self) { c in
                swatchChip(colour: c.colour, selected: appearance.hairColour == c,
                           id: CosmeticCatalog.id(hairColour: c)) { appearance.hairColour = c }
            }
        }
    }

    private var outfitSection: some View {
        section("OUTFIT") {
            ForEach(OutfitStyle.allCases, id: \.self) { o in
                var a = appearance; a.outfitStyle = o
                return avatarChip(preview: a, selected: appearance.outfitStyle == o,
                                  id: CosmeticCatalog.id(outfit: o)) { appearance.outfitStyle = o }
            }
        }
    }

    private var accentSection: some View {
        section("OUTFIT COLOUR") {
            ForEach(AccentColour.allCases, id: \.self) { a in
                swatchChip(colour: a.colour, selected: appearance.accentColour == a,
                           id: CosmeticCatalog.id(accent: a)) { appearance.accentColour = a }
            }
        }
    }

    private var accessorySection: some View {
        section("ACCESSORY") {
            ForEach(Accessory.allCases, id: \.self) { acc in
                var a = appearance; a.accessory = acc
                return avatarChip(preview: a, selected: appearance.accessory == acc,
                                  id: CosmeticCatalog.id(accessory: acc)) { appearance.accessory = acc }
            }
        }
    }

    // MARK: - Chips

    private func swatchChip(colour: Color, selected: Bool, id: String, apply: @escaping () -> Void) -> some View {
        let locked = !appStore.world.owns(id)
        return Button { choose(id, apply) } label: {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(colour)
                    .frame(width: 46, height: 46)
                    .overlay(Circle().strokeBorder(selected ? Theme.Colour.accent : Theme.Colour.cardBorder,
                                                   lineWidth: selected ? 3 : 1))
                    .opacity(locked ? 0.5 : 1)
                if locked { priceTag(CosmeticCatalog.cost(for: id)) }
            }
        }
        .buttonStyle(.plain)
    }

    private func avatarChip(preview: CharacterAppearance, selected: Bool, id: String, apply: @escaping () -> Void) -> some View {
        let locked = !appStore.world.owns(id)
        return Button { choose(id, apply) } label: {
            ZStack(alignment: .topTrailing) {
                PixelAvatarView(appearance: preview, status: .idle, size: 52)
                    .frame(width: 60, height: 60)
                    .background(Theme.Colour.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .strokeBorder(selected ? Theme.Colour.accent : Theme.Colour.cardBorder,
                                      lineWidth: selected ? 3 : 1))
                    .opacity(locked ? 0.55 : 1)
                if locked { priceTag(CosmeticCatalog.cost(for: id)) }
            }
        }
        .buttonStyle(.plain)
    }

    private func priceTag(_ cost: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "circle.fill").font(.system(size: 6)).foregroundStyle(Theme.Colour.textOnAccent)
            Text("\(cost)").font(.system(size: 9, weight: .heavy)).foregroundStyle(Theme.Colour.textOnAccent)
        }
        .padding(.horizontal, 4).padding(.vertical, 2)
        .background(Capsule().fill(Theme.Colour.accent))
        .offset(x: 6, y: -6)
    }

    // MARK: - Save bar

    private var saveBar: some View {
        Button { save() } label: {
            Text("Save character")
                .font(Theme.TypeScale.headline).foregroundStyle(Theme.Colour.buttonText)
                .frame(maxWidth: .infinity).padding(Theme.Spacing.md)
                .background(Theme.Colour.buttonFill)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
        }
        .padding(.horizontal, Theme.Spacing.lg).padding(.bottom, Theme.Spacing.lg)
    }

    private func toastView(_ text: String) -> some View {
        Text(text)
            .font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.buttonText)
            .padding(.horizontal, Theme.Spacing.md).padding(.vertical, Theme.Spacing.sm)
            .background(Capsule().fill(Theme.Colour.buttonFill))
            .padding(.bottom, 80)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions

    /// Select a cosmetic — free items apply immediately; premium ones buy if affordable.
    private func choose(_ id: String, _ apply: @escaping () -> Void) {
        if appStore.world.owns(id) {
            withAnimation(.easeInOut(duration: 0.15)) { apply() }
        } else if appStore.world.purchase(id) {
            withAnimation(.easeInOut(duration: 0.15)) { apply() }
            flash("Unlocked! ✨")
        } else {
            flash("Need \(CosmeticCatalog.cost(for: id)) coins")
        }
    }

    private func flash(_ message: String) {
        withAnimation { toast = message }
        Task {
            try? await Task.sleep(for: .seconds(1.4))
            withAnimation { toast = nil }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        onSave(appearance, trimmed.isEmpty ? "You" : trimmed)
        dismiss()
    }

    // MARK: - Section scaffold

    private func section(_ title: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title).font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) { content() }
                    .padding(.vertical, 4).padding(.horizontal, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Customizer") {
    CharacterCustomizerView(initial: .default, initialName: "You", onSave: { _, _ in })
        .environment(AppStore())
}
