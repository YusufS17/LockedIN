import SwiftUI

/// A full, fitted view of the saved room. Furniture and avatar remain separately
/// rendered layers; the onboarding composition does not clip its room to a card.
struct FirstRoomBeatView: View {
    let appearance: CharacterAppearance
    let displayName: String
    let onExplore: () -> Void

    @Environment(AppStore.self) private var appStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var character: StudyCharacter {
        StudyCharacter(id: "you", name: displayName, spriteAsset: "char_you", fallback: appearance)
    }

    var body: some View {
        ZStack {
            OnboardingApartmentBackdrop()
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        heading
                        room.aspectRatio(RoomLayout.imageSize.width / RoomLayout.imageSize.height,
                                         contentMode: .fit)
                        detail
                    }.padding(24)
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    heading
                    room.frame(maxHeight: .infinity)
                    detail
                }.padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 12)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("Enter your room", action: onExplore)
                .buttonStyle(OnboardingApartmentButtonStyle())
                .accessibilityIdentifier("onboarding.finish")
                .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 16)
                .background(OnboardingApartmentPalette.background.opacity(0.97))
        }
        .preferredColorScheme(.dark)
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your room is ready, \(displayName).")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(OnboardingApartmentPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text("Make yourself at home.")
                .font(.body).foregroundStyle(OnboardingApartmentPalette.muted)
        }
    }

    private var detail: some View {
        Text("Study here. Make it yours.")
            .font(.body).foregroundStyle(OnboardingApartmentPalette.muted)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var room: some View {
        GeometryReader { geo in
            let ratio = RoomLayout.imageSize.width / RoomLayout.imageSize.height
            let width = min(geo.size.width, geo.size.height * ratio)
            PersonalRoomScene(room: appStore.world.state.personalRoom, character: character, phase: .evening)
                .frame(width: width, height: width / ratio)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .accessibilityIdentifier("onboarding.arrivalRoom")
    }
}

#Preview("Room arrival") {
    FirstRoomBeatView(appearance: .default, displayName: "Alex", onExplore: {})
        .environment(AppStore())
}
