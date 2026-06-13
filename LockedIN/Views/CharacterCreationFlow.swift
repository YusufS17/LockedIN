import SwiftUI

// MARK: - CharacterCreationFlow — the REAL, working character creator
//
// Chains the functional CharacterCreatorView (mix-and-match skin/hair/outfit/accent
// with live preview) → PayoffBeatView (avatar reveal + name capture), then persists
// the chosen appearance + name to AppStore + UserDefaults so it survives relaunch.
//
// Wired into DemoFlowView in place of the static "Choose / Customise / Player ready"
// slides. Note: AvatarView is code-drawn, so this looks blockier than the static
// pixel-art mockups — but it is genuinely interactive.

struct CharacterCreationFlow: View {

    @Environment(AppStore.self) private var appStore
    var onDone: () -> Void

    // nil → still creating; non-nil → reveal + name step for that appearance
    @State private var chosen: CharacterAppearance?

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()

            if let appearance = chosen {
                PayoffBeatView(appearance: appearance) { name in
                    appStore.userCharacter = appearance
                    appStore.displayName = name
                    CharacterPersistence.save(appearance: appearance, displayName: name)
                    onDone()
                }
            } else {
                CharacterCreatorView(
                    onContinue: { appearance in
                        withAnimation(.easeInOut(duration: 0.3)) { chosen = appearance }
                    },
                    onSkip: {
                        appStore.userCharacter = .default
                        CharacterPersistence.save(appearance: .default, displayName: appStore.displayName)
                        onDone()
                    }
                )
            }
        }
        .statusBarHidden(true)
    }
}

#Preview {
    CharacterCreationFlow(onDone: {}).environment(AppStore())
}
