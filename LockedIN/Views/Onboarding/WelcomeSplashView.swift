import SwiftUI

/// The first beat gives the actual layered room the space previously taken by
/// intro cards and a large padlock. Standard text fits without a scrolling page.
struct WelcomeSplashView: View {
    let onContinue: () -> Void
    @Environment(AppStore.self) private var appStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack {
            OnboardingApartmentBackdrop()
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        heading
                        room.aspectRatio(RoomLayout.imageSize.width / RoomLayout.imageSize.height,
                                         contentMode: .fit)
                    }.padding(24)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    heading
                    room.frame(maxHeight: .infinity)
                }.padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 8)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(action: onContinue) {
                // Keep label gaps interactive independently of style expansion.
                Text("Create your character")
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
                .buttonStyle(OnboardingApartmentButtonStyle())
                .accessibilityIdentifier("onboarding.continue")
                .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 16)
                .background(OnboardingApartmentPalette.background.opacity(0.97))
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LockedIN")
                .font(.system(.largeTitle, design: .monospaced, weight: .bold))
                .foregroundStyle(OnboardingApartmentPalette.ink)
                .accessibilityAddTraits(.isHeader)
            Text("Make time.\nMake room.")
                .font(.system(.title, design: .rounded, weight: .semibold))
                .foregroundStyle(OnboardingApartmentPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Your own place to focus.")
                .font(.body).foregroundStyle(OnboardingApartmentPalette.muted)
        }
    }

    private var room: some View {
        GeometryReader { geo in
            let ratio = RoomLayout.imageSize.width / RoomLayout.imageSize.height
            let width = min(geo.size.width, geo.size.height * ratio)
            PersonalRoomScene(room: appStore.world.state.personalRoom,
                              character: appStore.userStudyCharacter, phase: .evening)
                .frame(width: width, height: width / ratio)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .accessibilityIdentifier("onboarding.roomPreview")
    }
}

#Preview("Welcome splash") {
    WelcomeSplashView(onContinue: {}).environment(AppStore())
}
