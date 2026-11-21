import SwiftUI

/// Native character creator. Available features edit independent runtime layers;
/// future wardrobe features never replace an existing saved outfit or accessory.
struct CharacterCustomizerView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ReducedMotionPreference private var reduceMotion

    let initial: CharacterAppearance
    var initialName: String = ""
    var onBack: (() -> Void)? = nil
    var isOnboarding = false
    var onSave: (CharacterAppearance, String) -> Void

    @State private var appearance: CharacterAppearance
    @State private var category: Category = .skin
    @State private var showsDiscardConfirmation = false

    init(initial: CharacterAppearance,
         initialName: String = "",
         onBack: (() -> Void)? = nil,
         isOnboarding: Bool = false,
         onSave: @escaping (CharacterAppearance, String) -> Void) {
        self.initial = initial
        self.initialName = initialName
        self.onBack = onBack
        self.isOnboarding = isOnboarding
        self.onSave = onSave
        _appearance = State(initialValue: initial)
    }

    private enum Category: String, CaseIterable, Identifiable {
        case skin, face, hair, hairColour, accent, accessory, comingSoon
        var id: String { rawValue }
        var title: String {
            switch self {
            case .skin: return "Skin"
            case .face: return "Face"
            case .hair: return "Hair"
            case .hairColour: return "Hair colour"
            case .accent: return "Colour"
            case .accessory: return "Glasses"
            case .comingSoon: return "Coming soon"
            }
        }
    }

    var body: some View {
        Group {
            if let issue = CharacterPersistence.recoveryIssue(defaults: appStore.defaults) {
                VStack(spacing: 0) {
                    header(title: "Saved avatar")
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your original is preserved").font(.headline)
                            Text(issue).fixedSize(horizontal: false, vertical: true)
                                .accessibilityIdentifier("avatar.recovery")
                        }.padding(24)
                    }
                }
            } else {
                editor
            }
        }
        .foregroundStyle(CreatorPalette.ink)
        .background(CreatorPalette.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var editor: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                header(title: isOnboarding ? "Create your character" : "Your character")
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        presentationSelector
                        preview(height: dynamicTypeSize.isAccessibilitySize ? 240 : max(112, min(280, geometry.size.height - 440)))
                        categoryRail
                        swatchArea
                        Button(action: randomize) {
                            Text("Randomize").font(.subheadline.weight(.semibold)).underline()
                                .frame(minHeight: 44).padding(.horizontal, 16)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("avatar.randomize")
                        .accessibilityLabel("Randomize appearance")
                    }
                    .padding(.horizontal, 20).padding(.bottom, 12)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { saveBar }
        .interactiveDismissDisabled(appearance != initial)
        .alert("Discard your character changes?", isPresented: $showsDiscardConfirmation) {
            Button("Discard changes", role: .destructive) { close() }
                .accessibilityIdentifier("avatar.discard")
            Button("Keep editing", role: .cancel) {}
                .accessibilityIdentifier("avatar.keepEditing")
        } message: {
            Text("Your saved character will stay as it was.")
        }
    }

    private func header(title: String) -> some View {
        HStack(spacing: 10) {
            Button(action: requestClose) {
                Image(systemName: "chevron.left").font(.headline)
                    .frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .accessibilityIdentifier("avatar.close")
            Text(title).font(.system(.title3, design: .rounded, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
    }

    private var presentationSelector: some View {
        HStack(spacing: 0) {
            presentationButton("M", selected: appearance.presentation == .masculine) {
                appearance.presentation = .masculine
            }
            .accessibilityLabel("Masculine presentation")
            .accessibilityIdentifier("avatar.presentation.masculine")
            presentationButton("F", selected: appearance.presentation == .feminine) {
                appearance.presentation = .feminine
            }
            .accessibilityLabel("Feminine presentation")
            .accessibilityIdentifier("avatar.presentation.feminine")
        }
        .background(CreatorPalette.panel, in: Capsule())
        .overlay(Capsule().strokeBorder(CreatorPalette.border))
        .fixedSize(horizontal: !dynamicTypeSize.isAccessibilitySize, vertical: false)
    }

    private func presentationButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.subheadline.weight(.bold))
                .foregroundStyle(selected ? CreatorPalette.buttonInk : CreatorPalette.ink)
                .frame(minWidth: 72, minHeight: 44)
                .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil)
                .background(selected ? CreatorPalette.amber : .clear, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func preview(height: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            CreatorApartmentStage()
            PixelAvatarView(appearance: appearance, status: .idle, size: min(240, height * 0.94))
                .padding(.bottom, 6)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .background(CreatorPalette.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(CreatorPalette.border.opacity(0.7)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Avatar: \(appearance.description), \(appearance.accessory.displayName)")
        .accessibilityIdentifier("avatar.preview")
    }

    private var categoryRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Category.allCases) { item in
                    Button { category = item } label: {
                        Text(item.title).font(.caption.weight(.semibold))
                            .foregroundStyle(category == item ? CreatorPalette.buttonInk : CreatorPalette.ink)
                            .padding(.horizontal, 12).frame(minHeight: 44)
                            .background(category == item ? CreatorPalette.amber : .clear,
                                        in: RoundedRectangle(cornerRadius: 9))
                            .contentShape(RoundedRectangle(cornerRadius: 9))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(category == item ? .isSelected : [])
                    .accessibilityIdentifier("avatar.category.\(item.rawValue)")
                }
            }
        }
        .accessibilityIdentifier("avatar.categories")
    }

    private var swatchArea: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) { swatches }
                .padding(.horizontal, 4).padding(.vertical, 4)
        }
        .frame(minHeight: 84, alignment: .top)
        .accessibilityIdentifier("avatar.options")
    }

    @ViewBuilder
    private var swatches: some View {
        switch category {
        case .skin:
            ForEach(Array([SkinTone.yellow, .light, .medium, .dark, .deep].enumerated()), id: \.element) { index, tone in
                Button { choose { appearance.skinTone = tone } } label: {
                    Text("\(index + 1)").font(.subheadline.weight(.bold))
                        .foregroundStyle(tone == .dark || tone == .deep ? CreatorPalette.ink : CreatorPalette.buttonInk)
                        .frame(width: 48, height: 48)
                        .background(tone.colour, in: Circle())
                        .overlay(Circle().strokeBorder(CreatorPalette.ink.opacity(0.4)))
                        .padding(4)
                        .overlay(Circle().strokeBorder(appearance.skinTone == tone ? CreatorPalette.amber : .clear, lineWidth: 2))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Skin \(index + 1)")
                .accessibilityAddTraits(appearance.skinTone == tone ? .isSelected : [])
                .accessibilityIdentifier("avatar.skin.\(tone.rawValue)")
            }
        case .face:
            ForEach(FaceStyle.allCases, id: \.self) { face in
                var option = appearance
                let _ = option.faceStyle = face
                avatarChip(option, selected: appearance.faceStyle == face, label: face.displayName,
                           identifier: "avatar.face.\(face.rawValue)") { appearance.faceStyle = face }
            }
        case .hair:
            ForEach(HairStyle.allCases, id: \.self) { hair in
                var option = appearance
                let _ = option.hairStyle = hair
                avatarChip(option, selected: appearance.hairStyle == hair, label: hair.displayName,
                           identifier: "avatar.hair.\(hair.rawValue)") { appearance.hairStyle = hair }
            }
        case .hairColour:
            ForEach(HairColour.allCases, id: \.self) { colour in
                colourChip(colour.colour, selected: appearance.hairColour == colour, label: colour.displayName,
                           identifier: "avatar.hairColour.\(colour.rawValue)") { appearance.hairColour = colour }
            }
        case .accent:
            ForEach(AccentColour.allCases, id: \.self) { colour in
                colourChip(colour.colour, selected: appearance.accentColour == colour, label: colour.displayName,
                           identifier: "avatar.accent.\(colour.rawValue)") { appearance.accentColour = colour }
            }
        case .accessory:
            ForEach([Accessory.none, .glasses], id: \.self) { accessory in
                var option = appearance
                let _ = option.accessory = accessory
                avatarChip(option, selected: appearance.accessory == accessory, label: accessory.displayName,
                           identifier: "avatar.accessory.\(accessory.rawValue)") { appearance.accessory = accessory }
            }
        case .comingSoon:
            ForEach([("Tops", "tshirt"), ("Bottoms", "figure.stand"), ("Shoes", "shoe"), ("Headphones", "headphones"), ("Hats", "graduationcap")], id: \.0) { title, symbol in
                VStack(spacing: 8) {
                    Image(systemName: symbol).font(.title3)
                    Text(title).font(.caption)
                    Text("Coming soon").font(.caption2)
                }
                .foregroundStyle(CreatorPalette.secondary)
                .frame(minWidth: 88, minHeight: 84)
                .padding(.horizontal, 8)
                .background(CreatorPalette.panel, in: RoundedRectangle(cornerRadius: 10))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(title), coming soon")
            }
        }
    }

    private func colourChip(_ colour: Color, selected: Bool, label: String, identifier: String,
                            action: @escaping () -> Void) -> some View {
        Button { choose(action) } label: {
            VStack(spacing: 6) {
                Circle().fill(colour).frame(width: 44, height: 44)
                    .overlay(Circle().strokeBorder(CreatorPalette.ink.opacity(0.3)))
                Text(label).font(.caption2).fixedSize(horizontal: false, vertical: true)
            }
            .frame(minWidth: 54, minHeight: 74).padding(.horizontal, 4)
            .background(selected ? CreatorPalette.amber.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(selected ? CreatorPalette.amber : .clear, lineWidth: 2))
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }

    private func avatarChip(_ option: CharacterAppearance, selected: Bool, label: String, identifier: String,
                            action: @escaping () -> Void) -> some View {
        Button { choose(action) } label: {
            VStack(spacing: 5) {
                itemPreview(option).frame(width: 58, height: 48)
                Text(label).font(.caption2).fixedSize(horizontal: false, vertical: true)
            }
            .frame(minWidth: 68, minHeight: 76).padding(.horizontal, 4)
            .background(CreatorPalette.panel, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(selected ? CreatorPalette.amber : CreatorPalette.border, lineWidth: selected ? 2 : 1))
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }

    private func itemPreview(_ option: CharacterAppearance) -> some View {
        let key = "creator-detail|\(option.presentation)|\(option.skinTone).\(option.hairStyle).\(option.hairColour).\(option.faceStyle).\(option.topStyle).\(option.bottomStyle).\(option.shoeStyle).\(option.accentColour).\(option.accessory)"
        let image = SpriteBakery.shared.image(key: key) {
            let grid = AvatarSpriteV3.grid(appearance: option).subgrid(x: 6, y: 0, cols: 36, rows: 30)
            return PixelRenderer.bake(grid: grid, palette: .avatarV3(option), rules: .avatarV3,
                                      outline: PixelRGBA(r: 31, g: 23, b: 20))
        }
        return Image(uiImage: image).interpolation(.none).resizable().scaledToFit().accessibilityHidden(true)
    }

    private var saveBar: some View {
        Button(action: save) {
            Text(isOnboarding ? "Continue" : "Save avatar")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(CreatorPalette.buttonInk)
                .frame(maxWidth: .infinity, minHeight: 52)
                .padding(.horizontal, 16).padding(.vertical, 2)
                .background(CreatorPalette.amber, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(CreatorPalette.ink.opacity(0.5)))
                .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(isOnboarding ? "avatar.continue" : "avatar.save")
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(CreatorPalette.background)
    }

    private func choose(_ action: () -> Void) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.15)) { action() }
    }

    private func randomize() {
        // Only available axes change. Existing garments and future accessories are
        // intentionally retained rather than silently replaced by starter options.
        choose {
            appearance.skinTone = SkinTone.allCases.randomElement() ?? appearance.skinTone
            appearance.faceStyle = FaceStyle.allCases.randomElement() ?? appearance.faceStyle
            appearance.hairStyle = HairStyle.allCases.randomElement() ?? appearance.hairStyle
            appearance.hairColour = HairColour.allCases.randomElement() ?? appearance.hairColour
            appearance.accentColour = AccentColour.allCases.randomElement() ?? appearance.accentColour
            if appearance.accessory == .none || appearance.accessory == .glasses {
                appearance.accessory = [Accessory.none, .glasses].randomElement() ?? appearance.accessory
            }
        }
    }

    private func requestClose() {
        if appearance != initial { showsDiscardConfirmation = true } else { close() }
    }

    private func close() {
        if let onBack { onBack() } else { dismiss() }
    }

    private func save() {
        guard CharacterPersistence.recoveryIssue(defaults: appStore.defaults) == nil else { return }
        onSave(appearance, initialName.trimmingCharacters(in: .whitespaces))
        if onBack == nil { dismiss() }
    }
}

private enum CreatorPalette {
    static let background = Color(red: 0.075, green: 0.090, blue: 0.105)
    static let panel = Color(red: 0.12, green: 0.14, blue: 0.16)
    static let border = Color(red: 0.29, green: 0.28, blue: 0.27)
    static let ink = Color(red: 0.98, green: 0.91, blue: 0.79)
    static let secondary = Color(red: 0.70, green: 0.68, blue: 0.63)
    static let amber = Color(red: 1.0, green: 0.66, blue: 0.23)
    static let buttonInk = Color(red: 0.10, green: 0.085, blue: 0.07)
}

/// A small native dressing-room set behind the independently rendered avatar.
private struct CreatorApartmentStage: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            ZStack {
                LinearGradient(colors: [CreatorPalette.panel, CreatorPalette.background], startPoint: .top, endPoint: .bottom)
                Rectangle().fill(Color(red: 0.28, green: 0.19, blue: 0.14))
                    .frame(height: height * 0.18).frame(maxHeight: .infinity, alignment: .bottom)
                Path { path in
                    for row in 0..<4 {
                        let y = height * (0.82 + Double(row) * 0.055)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    for column in 0..<7 {
                        let x = width * Double(column) / 6
                        path.move(to: CGPoint(x: width * 0.5 + (x - width * 0.5) * 0.65, y: height * 0.82))
                        path.addLine(to: CGPoint(x: x, y: height))
                    }
                }.stroke(Color.black.opacity(0.28), lineWidth: 1)
                Ellipse().fill(CreatorPalette.amber.opacity(0.10))
                    .frame(width: width * 0.54, height: height * 0.15)
                    .position(x: width * 0.5, y: height * 0.91)
                VStack(spacing: 0) {
                    Rectangle().fill(Color(red: 0.44, green: 0.29, blue: 0.18)).frame(width: width * 0.20, height: 4)
                    HStack(alignment: .top, spacing: 3) {
                        Rectangle().fill(Color(red: 0.24, green: 0.29, blue: 0.31)).frame(width: width * 0.045, height: height * 0.19)
                        Rectangle().fill(Color(red: 0.40, green: 0.32, blue: 0.23)).frame(width: width * 0.055, height: height * 0.24)
                        Rectangle().fill(Color(red: 0.24, green: 0.31, blue: 0.25)).frame(width: width * 0.05, height: height * 0.20)
                    }.padding(.top, 6)
                }.position(x: width * 0.14, y: height * 0.61)
                RoundedRectangle(cornerRadius: 2).fill(Color(red: 0.27, green: 0.33, blue: 0.35))
                    .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(Color(red: 0.48, green: 0.31, blue: 0.19), lineWidth: 5))
                    .frame(width: width * 0.13, height: height * 0.43)
                    .rotationEffect(.degrees(8)).position(x: width * 0.85, y: height * 0.65)
                Path { path in
                    path.move(to: CGPoint(x: width * 0.81, y: 0))
                    path.addLine(to: CGPoint(x: width * 0.81, y: height * 0.24))
                }.stroke(CreatorPalette.border, lineWidth: 2)
                Image(systemName: "lightbulb.fill").font(.system(size: 15))
                    .foregroundStyle(CreatorPalette.amber)
                    .shadow(color: CreatorPalette.amber.opacity(0.8), radius: 18)
                    .position(x: width * 0.81, y: height * 0.26)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview("Character creator") {
    CharacterCustomizerView(initial: .default, initialName: "You", onSave: { _, _ in })
        .environment(AppStore())
}
