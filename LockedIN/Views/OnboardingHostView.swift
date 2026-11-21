import SwiftUI

/// A short introduction with one continuous progress indicator. Avatar edits are
/// staged in AppStore until naming, while unsupported identities remain protected.
struct OnboardingHostView: View {
    @Environment(AppStore.self) private var appStore
    @ReducedMotionPreference private var reduceMotion
    @AppStorage(PersistenceKeys.onboarding) private var hasCompletedOnboarding = false

    private enum Beat: Int { case welcome, creator, name, arrival }
    @State private var beat: Beat = .welcome
    @State private var preparedIdentity = false
    @State private var draftName = ""

    var body: some View {
        Group {
            if let issue = CharacterPersistence.recoveryIssue(defaults: appStore.defaults) {
                recovery(issue)
            } else {
                introduction
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            guard !preparedIdentity else { return }
            preparedIdentity = true
            draftName = appStore.displayName
            // Never replace an existing supported or protected identity with a starter.
            if CharacterPersistence.load(defaults: appStore.defaults) == nil,
               CharacterPersistence.recoveryIssue(defaults: appStore.defaults) == nil {
                appStore.userCharacter = .starter
            }
        }
    }

    private var introduction: some View {
        ZStack {
            OnboardingApartmentBackdrop()
            switch beat {
            case .welcome:
                WelcomeSplashView(onContinue: { go(.creator) })
                    .transition(beatTransition)
            case .creator:
                CharacterCustomizerView(
                    initial: appStore.userCharacter,
                    initialName: draftName,
                    onBack: { go(.welcome) },
                    isOnboarding: true,
                    onSave: { appearance, _ in
                        appStore.userCharacter = appearance
                        go(.name)
                    }
                )
                .transition(beatTransition)
            case .name:
                AvatarRevealView(
                    appearance: appStore.userCharacter,
                    initialName: draftName,
                    onNameChange: { draftName = $0 },
                    onConfirm: { name in
                        guard CharacterPersistence.save(appearance: appStore.userCharacter,
                                                        displayName: name,
                                                        defaults: appStore.defaults) else { return }
                        draftName = name
                        appStore.displayName = name
                        go(.arrival)
                    }
                )
                .transition(beatTransition)
            case .arrival:
                FirstRoomBeatView(appearance: appStore.userCharacter,
                                  displayName: appStore.displayName,
                                  onExplore: complete)
                    .transition(beatTransition)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { progressHeader }
    }

    private var progressHeader: some View {
        HStack(spacing: 14) {
            if beat == .name || beat == .arrival {
                Button {
                    go(beat == .name ? .creator : .name)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(OnboardingApartmentPalette.ink)
                .accessibilityLabel("Previous onboarding step")
                .accessibilityIdentifier("onboarding.back")
            }
            ProgressView(value: Double(beat.rawValue + 1), total: 4)
                .tint(OnboardingApartmentPalette.amber)
                .accessibilityLabel("Introduction progress")
                .accessibilityValue("Step \(beat.rawValue + 1) of 4")
                .accessibilityIdentifier("onboarding.progress")
        }
        .padding(.horizontal, 24)
        .frame(minHeight: beat == .name || beat == .arrival ? 48 : 28)
        .background(OnboardingApartmentPalette.background)
    }

    private func recovery(_ issue: String) -> some View {
        ZStack {
            OnboardingApartmentBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Your saved avatar is preserved").font(.title2.bold())
                    Text(issue).accessibilityIdentifier("onboarding.avatarRecovery")
                    Text("You can enter your room with a temporary avatar preview. Your original saved look and name stay untouched, and avatar editing stays paused.")
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Continue with a temporary preview", action: complete)
                        .buttonStyle(OnboardingApartmentButtonStyle())
                        .accessibilityIdentifier("onboarding.avatarRecovery.continue")
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(OnboardingApartmentPalette.ink)
    }

    private func complete() { hasCompletedOnboarding = true }
    private func go(_ next: Beat) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { beat = next }
    }
    private var beatTransition: AnyTransition { .opacity }
}

/// Local first-run palette. Existing app screens retain their current theme until
/// their corresponding Pixel Apartment implementation slice is integrated.
enum OnboardingApartmentPalette {
    static let background = Color(red: 0.075, green: 0.086, blue: 0.106)
    static let surface = Color(red: 0.125, green: 0.133, blue: 0.149)
    static let ink = Color(red: 0.97, green: 0.925, blue: 0.83)
    static let muted = Color(red: 0.70, green: 0.68, blue: 0.63)
    static let amber = Color(red: 1.0, green: 0.69, blue: 0.29)
}

struct OnboardingApartmentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .foregroundStyle(OnboardingApartmentPalette.background)
            .padding(.horizontal, 18).padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(RoundedRectangle(cornerRadius: 14))
            .background(OnboardingApartmentPalette.amber, in: RoundedRectangle(cornerRadius: 14))
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.45)
    }
}

/// Architectural depth behind the live room layers, without ornamental clouds or
/// star particles. It deliberately remains still when Reduce Motion is enabled.
struct OnboardingApartmentBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [OnboardingApartmentPalette.background,
                                     Color(red: 0.13, green: 0.14, blue: 0.17),
                                     Color(red: 0.19, green: 0.14, blue: 0.105)],
                           startPoint: .top, endPoint: .bottomTrailing)
            Canvas { context, size in
                let width = size.width / 7
                for column in 0..<7 {
                    let roof = size.height * [0.48, 0.32, 0.43, 0.25, 0.39, 0.30, 0.45][column]
                    let x = CGFloat(column) * width
                    context.fill(Path(CGRect(x: x, y: roof, width: width - 4,
                                             height: size.height - roof)),
                                 with: .color(.black.opacity(0.12)))
                    for row in 0..<8 where (column + row) % 3 != 0 {
                        let rect = CGRect(x: x + width * 0.22,
                                          y: roof + 20 + CGFloat(row) * 38,
                                          width: width * 0.18, height: 12)
                        context.fill(Path(rect), with: .color(OnboardingApartmentPalette.amber.opacity(0.055)))
                    }
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

#Preview("Onboarding host") {
    OnboardingHostView().environment(AppStore())
}
