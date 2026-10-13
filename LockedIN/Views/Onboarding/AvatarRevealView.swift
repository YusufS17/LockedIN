import SwiftUI

// Preview and name the chosen outfit before saving identity.

struct AvatarRevealView: View {

    let appearance: CharacterAppearance
    var initialName: String = ""
    let onConfirm: (String) -> Void

    @ReducedMotionPreference private var reduceMotion
    @State private var name = ""
    @State private var burst = false
    @State private var avatarVisible = false
    @FocusState private var nameFocused: Bool

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()
            OnboardingBackdrop()

            ScrollView {
                VStack(spacing: 24) {
                    heading
                    pedestal
                    nameCard
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    PageDots(count: 6, active: 4)
                    Button("Meet your room") { confirm() }
                        .buttonStyle(StudioButtonStyle(primary: true))
                        .accessibilityIdentifier("onboarding.continue")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Theme.Colour.background)
            }
        }
        .onAppear {
            name = initialName
            withAnimation(reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.35).delay(0.1)) {
                avatarVisible = true
            }
            Task {
                try? await Task.sleep(for: .seconds(0.35))
                burst = true
            }
        }

    }

    // MARK: - Heading

    private var heading: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("You're all set!")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.Colour.textPrimary)
            Text("Your avatar is ready\nto start studying.")
                .font(.body)
                .foregroundStyle(Theme.Colour.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Pedestal

    private var pedestal: some View {
        ZStack {
            // Radial sunburst glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.Colour.sparkle.opacity(0.50),
                                 Theme.Colour.sparkle.opacity(0.10),
                                 .clear],
                        center: .center, startRadius: 20, endRadius: 130
                    )
                )
                .frame(width: 260, height: 260)

            // Gold floor pedestal
            Ellipse()
                .fill(Theme.Colour.accentSoft.opacity(0.65))
                .frame(width: 170, height: 44)
                .overlay(Ellipse().stroke(Theme.Colour.accent.opacity(0.5), lineWidth: 2))
                .offset(y: 82)

            SparkleBurst(trigger: burst, count: 12, radius: 96)

            AvatarView(appearance: appearance, status: .idle, size: 150)
                .scaleEffect(avatarVisible ? 1 : 0.4)
                .opacity(avatarVisible ? 1 : 0)
                .offset(y: 8)
        }
        .frame(height: 240)
    }

    // MARK: - Name card

    private var nameCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Name your avatar")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(Theme.Colour.textPrimary)

            TextField("Enter name…", text: $name)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(Theme.Colour.textPrimary)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .focused($nameFocused)
                .accessibilityIdentifier("onboarding.name")
                .submitLabel(.done)
                .onSubmit { confirm() }
                .onChange(of: name) { _, new in
                    if new.count > 24 { name = String(new.prefix(24)) }
                }
                .padding(Theme.Spacing.md)
                .background(PixelPanelShape(unit: 3).fill(Theme.Colour.background))
                .overlay(PixelPanelShape(unit: 3).stroke(Theme.Colour.cardBorder, lineWidth: 1.5))

            PixelSpeechBubble(text: "Your name in study rooms", icon: .users)
                .scaleEffect(0.9)
        }
        .padding(Theme.Spacing.md)
        .background(PixelPanelShape(unit: 4).fill(Theme.Colour.surface))
        .overlay(PixelPanelShape(unit: 4).stroke(Theme.Colour.cardBorder, lineWidth: 1.5))
    }

    private func confirm() {
        onConfirm(trimmedName.isEmpty ? "You" : trimmedName)
    }
}

#Preview("Avatar reveal") {
    AvatarRevealView(appearance: .default, initialName: "", onConfirm: { _ in })
        .environment(AppStore())
}
