import SwiftUI

/// Room is the everyday landing tab. Identity editing lives in Profile; decorating
/// stays beside the apartment. The persisted study flow owns session restoration.
struct HomeView: View {
    private enum Destination: String, Identifiable {
        case solo, world, decorate
        var id: String { rawValue }
    }
    var onShowFriends: () -> Void = {}
    @Environment(AppStore.self) private var appStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var destination: Destination?
    @State private var showRecoveryReset = false

    private var needsRecovery: Bool {
        appStore.studySession.recoveryIssue != nil || appStore.world.recoveryIssue != nil
    }

    var body: some View {
        ZStack {
            ApartmentNightBackdrop()
            if dynamicTypeSize.isAccessibilitySize || needsRecovery {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        recoveryNotices
                        if appStore.world.recoveryIssue == nil {
                            apartment.aspectRatio(RoomLayout.imageSize.width / RoomLayout.imageSize.height,
                                                  contentMode: .fit)
                        }
                        friendsRoute
                    }
                    .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 16)
                }
            } else {
                VStack(spacing: 12) {
                    header.padding(.horizontal, 20).padding(.top, 12)
                    apartment.frame(maxHeight: .infinity)
                    friendsRoute.padding(.horizontal, 20).padding(.bottom, 8)
                }
            }
        }
        .foregroundStyle(OnboardingApartmentPalette.ink)
        .safeAreaInset(edge: .bottom, spacing: 0) { studyDock }
        .confirmationDialog("Clear the unreadable session?", isPresented: $showRecoveryReset,
                            titleVisibility: .visible) {
            Button("Clear saved session", role: .destructive) {
                appStore.studySession.discardUnreadableSession()
            }
        } message: {
            Text("Only the unreadable session will be removed. Your room, avatar and earned progress will stay.")
        }
        .fullScreenCover(item: $destination) { target in
            switch target {
            case .solo: SoloRoomView()
            case .world: WorldView()
            case .decorate: PersonalRoomBuilderView()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Your room")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if !appStore.displayName.isEmpty {
                    Text("Hey, \(appStore.displayName).")
                        .font(.caption).foregroundStyle(OnboardingApartmentPalette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 4)
            Button { destination = .world } label: {
                HStack(spacing: 5) {
                    PixelIconView(icon: .coin, size: 16, tint: OnboardingApartmentPalette.amber)
                    Text(appStore.world.recoveryIssue == nil ? "\(appStore.world.state.progression.coins)" : "—")
                        .font(.subheadline.weight(.semibold)).monospacedDigit()
                }
                .padding(.horizontal, 10).frame(minHeight: 44)
                .background(OnboardingApartmentPalette.surface.opacity(0.8), in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(appStore.world.recoveryIssue == nil
                ? "\(appStore.world.state.progression.coins) coins. View progress"
                : "Saved world unavailable. View details")
            Button { destination = .decorate } label: {
                Image(systemName: "paintbrush.pointed")
                    .font(.body.weight(.semibold)).frame(width: 44, height: 44)
                    .background(OnboardingApartmentPalette.surface.opacity(0.8), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Decorate")
            .accessibilityIdentifier("room.decorate")
            .disabled(appStore.world.recoveryIssue != nil)
        }
    }

    private var apartment: some View {
        GeometryReader { geo in
            let ratio = RoomLayout.imageSize.width / RoomLayout.imageSize.height
            // A wide, uninterrupted room stage, with all current interactive layers
            // fitted together so the standing avatar remains on its saved floor.
            let width = min(geo.size.width * 1.07, geo.size.height * ratio)
            PersonalRoomScene(room: appStore.world.state.personalRoom,
                              character: appStore.userStudyCharacter, phase: .evening)
                .frame(width: width, height: width / ratio)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .accessibilityIdentifier("room.apartment")
    }

    @ViewBuilder
    private var recoveryNotices: some View {
        if let issue = appStore.studySession.recoveryIssue {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your saved session needs attention").font(.headline)
                Text(issue).font(.subheadline)
                Button("Clear unreadable session", role: .destructive) { showRecoveryReset = true }
                    .frame(minHeight: 44)
            }
            .modifier(ApartmentNoticeStyle())
        }
        if let issue = appStore.world.recoveryIssue {
            VStack(alignment: .leading, spacing: 10) {
                Text("Your saved world needs attention").font(.headline)
                Text(issue.message).font(.subheadline)
                if appStore.studySession.current != nil {
                    Text("Your pending session is kept. Return to its results when your world is available again.")
                        .font(.caption)
                }
            }
            .modifier(ApartmentNoticeStyle())
            .accessibilityIdentifier("world.recovery")
        }
    }

    private var friendsRoute: some View {
        Button(action: onShowFriends) {
            HStack(spacing: 12) {
                PixelIconView(icon: .users, size: 25, tint: OnboardingApartmentPalette.amber)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Friends").font(.subheadline.weight(.semibold))
                    Text("Private sessions are coming")
                        .font(.caption).foregroundStyle(OnboardingApartmentPalette.muted)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .padding(.horizontal, 16).padding(.vertical, 6)
            .background(OnboardingApartmentPalette.surface.opacity(0.82), in: RoundedRectangle(cornerRadius: 14))
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open friends")
        .accessibilityHint("Private friend sessions are not connected yet")
        .accessibilityIdentifier("room.friends")
    }

    private var studyDock: some View {
        VStack(spacing: 6) {
            Button { destination = .solo } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill").font(.subheadline).accessibilityHidden(true)
                    Text(studyActionTitle).font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 4)
                    Image(systemName: "arrow.right").accessibilityHidden(true)
                }
                .foregroundStyle(OnboardingApartmentPalette.background)
                .frame(maxWidth: .infinity, minHeight: 54)
                .padding(.horizontal, 18).padding(.vertical, 4)
                .background(OnboardingApartmentPalette.amber, in: RoundedRectangle(cornerRadius: 14))
                .contentShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("study.start")
            .disabled(appStore.studySession.recoveryIssue != nil ||
                      (appStore.world.recoveryIssue != nil && appStore.studySession.current == nil))
            .opacity(appStore.studySession.recoveryIssue != nil ||
                     (appStore.world.recoveryIssue != nil && appStore.studySession.current == nil) ? 0.45 : 1)
            if let subject = appStore.studySession.current?.config.subject {
                Text(subject).font(.caption).foregroundStyle(OnboardingApartmentPalette.muted)
                    .lineLimit(2).multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 10)
        .background(OnboardingApartmentPalette.background.opacity(0.96))
    }

    private var studyActionTitle: String {
        guard let session = appStore.studySession.current else { return "Start studying" }
        switch session.phase {
        case .focusing, .onBreak: return "Return to your session"
        case .goalCheck: return "Finish your check-in"
        case .results: return "View your results"
        }
    }
}

struct ApartmentNoticeStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(OnboardingApartmentPalette.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .strokeBorder(OnboardingApartmentPalette.amber.opacity(0.35)))
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview { ApartmentAppShell().environment(AppStore()) }
