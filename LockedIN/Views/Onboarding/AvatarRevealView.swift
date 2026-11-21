import SwiftUI

/// A concise naming beat. A callback preserves an unfinished name when returning
/// to the creator; only the host's confirm action writes the saved identity.
struct AvatarRevealView: View {
    let appearance: CharacterAppearance
    var initialName: String = ""
    var onNameChange: ((String) -> Void)? = nil
    let onConfirm: (String) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var name = ""
    @FocusState private var nameFocused: Bool

    var body: some View {
        ZStack {
            OnboardingApartmentBackdrop()
            ScrollView {
                VStack(spacing: 24) {
                    Text("What should we call you?")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(OnboardingApartmentPalette.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    AvatarView(appearance: appearance, status: .idle,
                               size: dynamicTypeSize.isAccessibilitySize ? 110 : 140)
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(OnboardingApartmentPalette.surface, in: RoundedRectangle(cornerRadius: 24))
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your name").font(.subheadline.weight(.semibold))
                            .foregroundStyle(OnboardingApartmentPalette.muted)
                        TextField("Enter your name", text: $name)
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(OnboardingApartmentPalette.ink)
                            .textFieldStyle(.plain)
                            .focused($nameFocused)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            .onSubmit(confirm)
                            .accessibilityLabel("Your name")
                            .accessibilityIdentifier("onboarding.name")
                            .padding(16)
                            .background(OnboardingApartmentPalette.surface,
                                        in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(OnboardingApartmentPalette.muted.opacity(0.35)))
                    }
                }.padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("Continue to your room", action: confirm)
                .buttonStyle(OnboardingApartmentButtonStyle())
                .accessibilityIdentifier("onboarding.continue")
                .padding(.horizontal, 24).padding(.vertical, 16)
                .background(OnboardingApartmentPalette.background.opacity(0.97))
        }
        .onAppear { name = initialName }
        .onChange(of: name) { _, new in
            let bounded = String(new.prefix(24))
            if name != bounded { name = bounded }
            onNameChange?(bounded)
        }
    }

    private func confirm() {
        nameFocused = false
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        onConfirm(trimmed.isEmpty ? "You" : trimmed)
    }
}

#Preview("Avatar name") {
    AvatarRevealView(appearance: .default, onConfirm: { _ in })
}
