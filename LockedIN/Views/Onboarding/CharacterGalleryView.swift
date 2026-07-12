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

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    private var selected: StudyCharacter { CharacterCatalog.character(id: selectedID) }

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
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Choose your\nstudy avatar")
                .font(Theme.TypeScale.title)
                .foregroundStyle(Theme.Colour.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Pick a starting look — you'll fully customise it next.")
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
            .background(PixelPanelShape(unit: 4).fill(Theme.Colour.surface))
            .overlay(
                PixelPanelShape(unit: 4)
                    .stroke(isSelected ? Theme.Colour.accent : Theme.Colour.cardBorder,
                            lineWidth: isSelected ? 3 : 1.5)
            )
            .scaleEffect(isSelected ? 1.03 : 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: Theme.Spacing.md) {
            PageDots(count: 6, active: 2)
            Button("NEXT") { confirm() }
                .buttonStyle(PixelButtonStyle(kind: .gold))
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.xl)
    }

    /// Commit the base pick; naming + persistence happen at the reveal beat.
    private func confirm() {
        appStore.selectedCharacterID = selectedID
        appStore.userCharacter = selected.fallback
        onContinue()
    }
}

#Preview {
    CharacterGalleryView(onContinue: {}).environment(AppStore())
}
