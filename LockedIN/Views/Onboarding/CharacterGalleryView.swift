import SwiftUI

// MARK: - CharacterGalleryView — real "Choose your study avatar" (ONB-02)
//
// Functional gallery: pick from CharacterCatalog (real sprites when present, code-drawn
// fallback otherwise), name your avatar, continue. Persists selection + name to AppStore
// + UserDefaults so it represents the user everywhere and survives relaunch (ONB-04).
// Matches the "Choose your study avatar" + "Player ready" mockups.

struct CharacterGalleryView: View {

    @Environment(AppStore.self) private var appStore
    var onContinue: () -> Void

    @State private var selectedID = CharacterCatalog.first.id
    @State private var name = ""
    @State private var showCustomizer = false

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    private var selected: StudyCharacter { CharacterCatalog.character(id: selectedID) }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(CharacterCatalog.all) { character in
                            tile(character)
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }

                footer
            }
        }
        .onAppear {
            selectedID = appStore.selectedCharacterID
            if !appStore.displayName.isEmpty { name = appStore.displayName }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Choose your study avatar")
                .font(Theme.TypeScale.title)
                .foregroundStyle(Theme.Colour.textPrimary)
            Text("Pick the one that's you. You can rename it below.")
                .font(Theme.TypeScale.body)
                .foregroundStyle(Theme.Colour.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.lg)
    }

    // MARK: - Tile

    private func tile(_ character: StudyCharacter) -> some View {
        let isSelected = character.id == selectedID
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedID = character.id }
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                SpriteAvatarView(character: character, status: .idle, size: 96, animated: false)
                Text(character.name)
                    .font(Theme.TypeScale.captionBold)
                    .foregroundStyle(Theme.Colour.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(Theme.Colour.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .strokeBorder(isSelected ? Theme.Colour.accent : Theme.Colour.cardBorder,
                                  lineWidth: isSelected ? 3 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer (name + continue)

    private var footer: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Text("Name").font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.textSecondary)
                TextField("Enter a name…", text: $name)
                    .font(Theme.TypeScale.headline)
                    .foregroundStyle(Theme.Colour.textPrimary)
                    .textFieldStyle(.plain)
                    .onChange(of: name) { _, new in
                        if new.count > 24 { name = String(new.prefix(24)) }
                    }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colour.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))

            Button(action: confirm) {
                Text("Continue")
                    .font(Theme.TypeScale.headline)
                    .foregroundStyle(Theme.Colour.buttonText)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colour.buttonFill)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
            }

            Button { showCustomizer = true } label: {
                Label("Customise this character", systemImage: "wand.and.stars")
                    .font(Theme.TypeScale.captionBold)
                    .foregroundStyle(Theme.Colour.textSecondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.xl)
        .fullScreenCover(isPresented: $showCustomizer) {
            CharacterCustomizerView(initial: selected.fallback, initialName: trimmedName) { appearance, newName in
                appStore.userCharacter = appearance
                appStore.displayName = newName
                appStore.selectedCharacterID = selectedID
                CharacterPersistence.save(appearance: appearance, displayName: newName)
                onContinue()
            }
            .environment(appStore)
        }
    }

    private func confirm() {
        appStore.selectedCharacterID = selectedID
        appStore.displayName = trimmedName.isEmpty ? "You" : trimmedName
        appStore.userCharacter = selected.fallback
        CharacterPersistence.save(appearance: selected.fallback, displayName: appStore.displayName)
        onContinue()
    }
}

#Preview {
    CharacterGalleryView(onContinue: {}).environment(AppStore())
}
