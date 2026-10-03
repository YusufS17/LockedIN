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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let initial: CharacterAppearance
    var initialName: String = ""
    var onBack: (() -> Void)? = nil
    var onSave: (CharacterAppearance, String) -> Void

    @State private var appearance: CharacterAppearance
    @State private var category: Category = .hair
    @State private var toast: String?
    @State private var showsDiscardConfirmation = false

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
        VStack(spacing: 0) {
            StudioHeader(title: "Your wardrobe", subtitle: "A character that feels like you", closeIdentifier: "avatar.close", compactAtAccessibility: true, close: requestClose)
            if !dynamicTypeSize.isAccessibilitySize {
                preview.padding(.horizontal, 24).padding(.bottom, 14)
            }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if dynamicTypeSize.isAccessibilitySize { preview }
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 10) {
                            StudioSectionHeading(title: "Find your look", detail: "Mix every piece independently.")
                            shuffleButton
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        HStack(alignment: .center) {
                            StudioSectionHeading(title: "Find your look", detail: "Mix every piece independently.")
                            Spacer()
                            shuffleButton
                        }
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Category.allCases) { c in
                                Button { category = c } label: {
                                    HStack(spacing: 7) {
                                        PixelIconView(icon: c.icon, size: 17)
                                        Text(c.title).font(.caption.weight(.semibold))
                                    }
                                    .padding(.horizontal, 12).frame(minHeight: 44)
                                    .modifier(StudioSelectionTile(selected: category == c))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(c.title)
                                .accessibilityAddTraits(category == c ? .isSelected : [])
                                .accessibilityIdentifier("avatar.category.\(c.rawValue)")
                            }
                        }
                    }
                    .accessibilityIdentifier("avatar.categories")
                    swatchArea
                    Text("Owned looks are free to try. Tap a priced look to unlock it with earned coins.")
                        .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24).padding(.bottom, 24)
            }
        }
        .foregroundStyle(Theme.Colour.textPrimary)
        .background(Theme.Colour.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) { saveBar.background(Theme.Colour.background) }
        .overlay(alignment: .bottom) { if let toast { toastView(toast) } }
        .task(id: toast) {
            guard toast != nil else { return }
            do { try await Task.sleep(for: .seconds(3)) } catch { return }
            withAnimation { toast = nil }
        }
        .interactiveDismissDisabled(appearance != initial)
        .alert("Discard your outfit changes?", isPresented: $showsDiscardConfirmation) {
            Button("Discard changes", role: .destructive) { close() }
                .accessibilityIdentifier("avatar.discard")
            Button("Keep editing", role: .cancel) {}
                .accessibilityIdentifier("avatar.keepEditing")
        } message: {
            Text("Your saved outfit will stay as it was. Any unlocked items stay owned.")
        }
    }

    private var shuffleButton: some View {
        Button(action: randomise) {
            Label("Shuffle", systemImage: "dice")
                .font(.caption.weight(.semibold)).padding(12)
        }
        .background(Theme.Colour.surface, in: Capsule())
        .accessibilityLabel("Randomise appearance")
    }

    private var preview: some View {
        VStack(spacing: 0) {
            HStack {
                StudioEyebrow(text: "Dressing room")
                Spacer()
                StudioCoinBalance(coins: coins)
            }.padding(.horizontal, 16).padding(.top, 12)
            ZStack(alignment: .bottom) {
                WardrobeStage().frame(height: 152)
                PixelAvatarView(appearance: appearance, status: .idle, size: 150)
                    .padding(.bottom, 10)
            }
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(initialName.isEmpty ? "Your study companion" : initialName)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                    Text("\(appearance.topStyle.displayName) · \(appearance.bottomStyle.displayName) · \(appearance.shoeStyle.displayName)")
                        .font(.caption2).foregroundStyle(Theme.Colour.textSecondary)
                }
                Spacer()
                Image(systemName: "person.crop.square").foregroundStyle(Theme.Colour.testBadgeFg)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Theme.Colour.surface)
        }
        .background(Theme.Colour.surfaceMid.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.Colour.cardBorder))
    }

    // MARK: - Swatch area

    private var swatchColumns: [GridItem] {
        [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 140 : 86), spacing: 12)]
    }

    private var swatchArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StudioEyebrow(text: category.title)
                Spacer()
                Text("Choose a look").font(.caption2).foregroundStyle(Theme.Colour.textSecondary)
            }
            LazyVGrid(columns: swatchColumns, spacing: 12) { swatches }
        }.frame(maxWidth: .infinity, alignment: .leading)
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
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Circle().fill(colour).frame(width: 42, height: 42)
                        .overlay(Circle().strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
                    if locked, let id { priceTag(CosmeticCatalog.cost(for: id)) }
                }.frame(height: 62)
                Text(label).font(.caption.weight(.medium)).multilineTextAlignment(.center)
                inventoryState(selected: selected, locked: locked, id: id)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 10)
            .foregroundStyle(Theme.Colour.textPrimary)
            .modifier(StudioSelectionTile(selected: selected))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label)\(selected ? ", selected" : "")")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityHint(locked ? "Unlock for \(id.map { CosmeticCatalog.cost(for: $0) } ?? 0) earned coins" : "Try on this look")
    }

    private func avatarChip(preview: CharacterAppearance, selected: Bool, id: String?, label: String,
                            apply: @escaping () -> Void) -> some View {
        let locked = id.map { !appStore.world.owns($0) } ?? false
        return Button { choose(id, apply) } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    itemPreview(preview).frame(height: 86).padding(.horizontal, 8)
                    if locked, let id { priceTag(CosmeticCatalog.cost(for: id)) }
                }
                Text(label).font(.caption.weight(.medium)).multilineTextAlignment(.center)
                inventoryState(selected: selected, locked: locked, id: id)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 10)
            .foregroundStyle(Theme.Colour.textPrimary)
            .modifier(StudioSelectionTile(selected: selected))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label)\(selected ? ", selected" : "")")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityHint(locked ? "Unlock for \(id.map { CosmeticCatalog.cost(for: $0) } ?? 0) earned coins" : "Try on this look")
    }

    private func inventoryState(selected: Bool, locked: Bool, id: String?) -> some View {
        HStack(spacing: 3) {
            if selected { Image(systemName: "checkmark") }
            else if locked { Image(systemName: "lock.fill") }
            Text(selected ? "Wearing" : locked ? "\(id.map { CosmeticCatalog.cost(for: $0) } ?? 0) coins" : "Owned")
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(selected ? Theme.Colour.testBadgeFg : Theme.Colour.textSecondary)
    }

    /// Show the feature being chosen at a useful scale, using the real sprite.
    private func itemPreview(_ a: CharacterAppearance) -> some View {
        let crop: (x: Int, y: Int, width: Int, height: Int)
        switch category {
        case .hair, .face, .accessory: crop = (6, 0, 36, 30)
        case .top: crop = (9, 23, 30, 27)
        case .bottoms: crop = (12, 45, 24, 18)
        case .shoes: crop = (12, 54, 26, 10)
        default: crop = (0, 0, 48, 64)
        }
        let key = "wardrobe-detail|\(category.rawValue)|\(a.skinTone).\(a.hairStyle).\(a.hairColour).\(a.faceStyle).\(a.topStyle).\(a.bottomStyle).\(a.shoeStyle).\(a.accentColour).\(a.accessory)"
        let image = SpriteBakery.shared.image(key: key) {
            let grid = AvatarSpriteV3.grid(appearance: a)
                .subgrid(x: crop.x, y: crop.y, cols: crop.width, rows: crop.height)
            return PixelRenderer.bake(grid: grid, palette: .avatarV3(a), rules: .avatarV3,
                                      outline: PixelRGBA(r: 31, g: 23, b: 20))
        }
        return Image(uiImage: image).interpolation(.none).resizable().scaledToFit()
            .padding(8).accessibilityHidden(true)
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
        VStack(spacing: 9) {
            Button("Save avatar") { save() }
                .buttonStyle(StudioButtonStyle(primary: true))
                .accessibilityIdentifier("avatar.save")
            if !dynamicTypeSize.isAccessibilitySize {
                Text("Save to keep your outfit. Unlocked items stay owned.")
                    .font(.caption2).foregroundStyle(Theme.Colour.textSecondary)
            }
        }
        .padding(.horizontal, 24).padding(.vertical, 12)
    }

    private func toastView(_ text: String) -> some View {
        Text(text)
            .font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.buttonText)
            .padding(.horizontal, Theme.Spacing.md).padding(.vertical, Theme.Spacing.sm)
            .background(PixelPanelShape(unit: 2).fill(Theme.Colour.buttonFill))
            .multilineTextAlignment(.center)
            .accessibilityIdentifier("avatar.feedback")
            .padding(.horizontal, 24)
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
            flash("Need \(max(0, CosmeticCatalog.cost(for: id) - coins)) more coins. You have \(coins).")
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

    }

    private func requestClose() {
        if appearance != initial { showsDiscardConfirmation = true } else { close() }
    }

    private func close() {
        if let onBack { onBack() } else { dismiss() }
    }

    private func save() {
        onSave(appearance, initialName.trimmingCharacters(in: .whitespaces))
        if onBack == nil { dismiss() }
    }
}

/// A quiet dressing-room backdrop; the avatar remains a live, editable sprite.
private struct WardrobeStage: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                RoundedRectangle(cornerRadius: 80)
                    .fill(Theme.Colour.surface.opacity(0.65))
                    .frame(width: w * 0.55, height: h * 0.94)
                    .overlay(RoundedRectangle(cornerRadius: 80)
                        .strokeBorder(Theme.Colour.cardBorder.opacity(0.65), lineWidth: 1))
                    .position(x: w / 2, y: h * 0.47)
                Path { path in
                    path.move(to: CGPoint(x: w * 0.19, y: h * 0.84))
                    path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.67))
                    path.addLine(to: CGPoint(x: w * 0.81, y: h * 0.84))
                    path.addLine(to: CGPoint(x: w * 0.5, y: h))
                    path.closeSubpath()
                }
                .fill(Theme.Colour.accentSoft.opacity(0.6))
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Theme.Colour.cardBorder.opacity(0.6))
                        .frame(width: w * 0.26, height: 2).padding(.bottom, 12)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview("Customizer") {
    CharacterCustomizerView(initial: .default, initialName: "You", onSave: { _, _ in })
        .environment(AppStore())
}
