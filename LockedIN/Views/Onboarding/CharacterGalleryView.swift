import SwiftUI

// Choose a real catalogue base; naming and identity save happen at reveal.

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
                ScrollView {
                    header
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
            Text("Choose your study avatar")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.Colour.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Pick a starting look — you'll fully customise it next.")
                .font(.body)
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
                    .font(.system(.caption, design: .rounded, weight: .semibold))
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
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.Colour.textPrimary, Theme.Colour.accent)
                        .font(.title3)
                        .padding(10)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(character.name), starting look")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("onboarding.avatar.\(character.id)")
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: Theme.Spacing.md) {
            PageDots(count: 6, active: 2)
            Button("Customise this look") { confirm() }
                .buttonStyle(StudioButtonStyle(primary: true))
                .accessibilityIdentifier("onboarding.continue")
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
