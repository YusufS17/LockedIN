import SwiftUI

/// Native tabs separate the apartment, social surface and saved identity. Active
/// study state belongs to AppStore and is unaffected by selecting another tab.
enum ApartmentTab: Hashable { case room, friends, profile }

struct ApartmentAppShell: View {
    @State private var selectedTab: ApartmentTab

    init(initialTab: ApartmentTab = .room) {
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(onShowFriends: { selectedTab = .friends })
                .tabItem { Label("Room", systemImage: "house.fill") }
                .tag(ApartmentTab.room)
            ApartmentFriendsView(onReturnToRoom: { selectedTab = .room })
                .tabItem { Label("Friends", systemImage: "person.2.fill") }
                .tag(ApartmentTab.friends)
            ApartmentProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(ApartmentTab.profile)
        }
        .tint(OnboardingApartmentPalette.amber)
        .toolbarBackground(OnboardingApartmentPalette.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("app.tabs")
    }
}

private struct ApartmentFriendsView: View {
    var onReturnToRoom: () -> Void
    @Environment(AppStore.self) private var appStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showDemo = false

    var body: some View {
        ZStack {
            ApartmentNightBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Friends")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .accessibilityAddTraits(.isHeader)
                    HStack {
                        Spacer(minLength: 0)
                        PixelIconView(icon: .users, size: dynamicTypeSize.isAccessibilitySize ? 76 : 112,
                                      tint: OnboardingApartmentPalette.amber)
                            .padding(36)
                            .background(RadialGradient(colors: [OnboardingApartmentPalette.amber.opacity(0.12), .clear],
                                                       center: .center, startRadius: 10, endRadius: 110))
                            .accessibilityHidden(true)
                        Spacer(minLength: 0)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Not connected yet")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                        Text("Friend invites and private sessions are still being built.")
                            .font(.body).foregroundStyle(OnboardingApartmentPalette.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityIdentifier("friends.unavailable")
                    Divider().overlay(OnboardingApartmentPalette.muted.opacity(0.25))
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Demo study club").font(.headline)
                        Text("Try a room with simulated companions. No real friends are connected.")
                            .font(.subheadline).foregroundStyle(OnboardingApartmentPalette.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        if appStore.studySession.current != nil {
                            Button("Return to your session", action: onReturnToRoom)
                                .buttonStyle(OnboardingApartmentButtonStyle())
                                .accessibilityIdentifier("friends.returnToSession")
                        } else {
                            Button("Try a demo club") { showDemo = true }
                                .buttonStyle(OnboardingApartmentButtonStyle())
                                .accessibilityIdentifier("study.club")
                                .disabled(appStore.studySession.recoveryIssue != nil || appStore.world.recoveryIssue != nil)
                            if appStore.studySession.recoveryIssue != nil || appStore.world.recoveryIssue != nil {
                                Text("Open Room to review your saved-data message.")
                                    .font(.caption).foregroundStyle(OnboardingApartmentPalette.muted)
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
        .foregroundStyle(OnboardingApartmentPalette.ink)
        .fullScreenCover(isPresented: $showDemo) { GroupRoomView() }
    }
}

private struct ApartmentProfileView: View {
    private enum Destination: String, Identifiable {
        case avatar, world, contract
        var id: String { rawValue }
    }
    @Environment(AppStore.self) private var appStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var destination: Destination?

    var body: some View {
        ZStack {
            ApartmentNightBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    VStack(spacing: 18) {
                        SpriteAvatarView(character: appStore.userStudyCharacter, status: .idle,
                                         size: dynamicTypeSize.isAccessibilitySize ? 136 : 172,
                                         animated: false)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Your avatar: \(appStore.userCharacter.description)")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(OnboardingApartmentPalette.surface.opacity(0.65),
                                        in: RoundedRectangle(cornerRadius: 24))
                        Text(appStore.displayName.isEmpty ? "Your profile" : "Hey, \(appStore.displayName).")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                        Button("Edit avatar") { destination = .avatar }
                            .buttonStyle(OnboardingApartmentButtonStyle())
                            .accessibilityIdentifier("profile.editAvatar")
                    }
                    if CharacterPersistence.recoveryIssue(defaults: appStore.defaults) != nil {
                        Text("Your original avatar is preserved. Open Edit avatar for details.")
                            .font(.subheadline).foregroundStyle(OnboardingApartmentPalette.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    progress
                }
                .padding(24)
            }
        }
        .foregroundStyle(OnboardingApartmentPalette.ink)
        .fullScreenCover(item: $destination) { target in
            switch target {
            case .avatar:
                CharacterCustomizerView(initial: appStore.userCharacter, initialName: appStore.displayName) { appearance, name in
                    guard CharacterPersistence.save(appearance: appearance, displayName: name,
                                                    defaults: appStore.defaults) else { return }
                    appStore.userCharacter = appearance
                    appStore.displayName = name
                }
            case .world: WorldView()
            case .contract: RoomFlowView()
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Profile").font(.system(.title, design: .rounded, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Menu {
                Button("Your progress", systemImage: "chart.bar") { destination = .world }
                Button("Test commitment demo", systemImage: "flask") { destination = .contract }
                    .disabled(appStore.studySession.current != nil || appStore.studySession.recoveryIssue != nil ||
                              appStore.world.recoveryIssue != nil)
            } label: {
                Image(systemName: "ellipsis").font(.body.weight(.bold))
                    .frame(width: 44, height: 44)
                    .background(OnboardingApartmentPalette.surface, in: Circle())
            }
            .accessibilityLabel("More options")
        }
    }

    @ViewBuilder
    private var progress: some View {
        if let issue = appStore.world.recoveryIssue {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your saved world needs attention").font(.headline)
                Text(issue.message).font(.subheadline)
                Button("View details") { destination = .world }
                    .frame(minHeight: 44)
            }.modifier(ApartmentNoticeStyle())
        } else {
            Button { destination = .world } label: {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Your progress").font(.headline)
                        Spacer()
                        Image(systemName: "arrow.up.right").accessibilityHidden(true)
                    }
                    Text("Level \(appStore.world.state.progression.level)")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    ProgressView(value: appStore.world.state.progression.levelProgress)
                        .tint(OnboardingApartmentPalette.amber)
                        .accessibilityLabel("Progress to level \(appStore.world.state.progression.level + 1)")
                    Text("\(appStore.world.state.progression.sessionsCompleted) sessions · \(appStore.world.state.progression.coins) coins")
                        .font(.subheadline).foregroundStyle(OnboardingApartmentPalette.muted)
                }
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("profile.progress")
        }
    }
}

#Preview { ApartmentAppShell().environment(AppStore()) }
