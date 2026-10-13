import SwiftUI

struct HomeView: View {
    enum Destination: String, Identifiable {
        case solo, group, world, avatar, decorate, contract
        var id: String { rawValue }
    }
    @Environment(AppStore.self) private var appStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title) private var welcomeSize = 27.0
    @State private var destination: Destination?
    @State private var showRecoveryReset = false
    private var progression: Progression { appStore.world.state.progression }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                if let issue = appStore.studySession.recoveryIssue {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(issue).font(.subheadline)
                        Button("Clear unreadable session", role: .destructive) { showRecoveryReset = true }
                    }.modifier(StudioCard())
                }
                if let issue = appStore.world.recoveryIssue {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your saved world needs attention").font(.headline)
                        Text(issue.message).font(.subheadline)
                        if appStore.studySession.current != nil {
                            Text("Your pending session is kept. Return to its results when your world is available again.").font(.caption)
                        }
                    }.modifier(StudioCard())
                    .accessibilityIdentifier("world.recovery")
                }
                welcome
                if appStore.world.recoveryIssue == nil { roomCard }
                routeLayout {
                    homeRoute("Edit avatar", detail: "Hair, clothes & you", icon: .shirt, destination: .avatar)
                    homeRoute("Decorate", detail: "Make room for you", icon: .house, destination: .decorate)
                }
                clubCard
                if appStore.world.recoveryIssue == nil { progressCard }
                Text("A room that grows with you, one session at a time.")
                    .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
                    .frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.bottom, 8)
            }
            .padding(.horizontal, 24).padding(.top, 12)
        }
        .foregroundStyle(Theme.Colour.textPrimary)
        .background(Theme.Colour.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                Button { destination = .solo } label: {
                    HStack {
                        Image(systemName: "play.fill").font(.system(size: 12)).fixedSize().accessibilityHidden(true)
                        Text(studyActionTitle)
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(StudioButtonStyle(primary: true))
                .accessibilityIdentifier("study.start")
                .disabled(appStore.studySession.recoveryIssue != nil ||
                          (appStore.world.recoveryIssue != nil && appStore.studySession.current == nil))
                Text(appStore.studySession.current?.config.subject ?? "Your pace. Your space.").font(.caption).foregroundStyle(Theme.Colour.textSecondary)
            }
            .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 8)
            .background(Theme.Colour.background.opacity(0.97))
        }
        .confirmationDialog("Clear the unreadable session?", isPresented: $showRecoveryReset, titleVisibility: .visible) {
            Button("Clear saved session", role: .destructive) { appStore.studySession.discardUnreadableSession() }
        } message: {
            Text("Only the unreadable session will be removed. Your room, avatar and earned progress will stay.")
        }
        .preferredColorScheme(.light)
        .fullScreenCover(item: $destination) { target in
            switch target {
            case .solo: SoloRoomView()
            case .group: GroupRoomView()
            case .world: WorldView()
            case .decorate: PersonalRoomBuilderView()
            case .contract: RoomFlowView()
            case .avatar:
                CharacterCustomizerView(initial: appStore.userCharacter, initialName: appStore.displayName) { appearance, name in
                    appStore.userCharacter = appearance
                    appStore.displayName = name
                    CharacterPersistence.save(appearance: appearance, displayName: name, defaults: appStore.defaults)
                }
            }
        }
    }

    private var routeLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
    }

    private var studyActionTitle: String {
        guard let session = appStore.studySession.current else { return "Start studying" }
        switch session.phase {
        case .focusing, .onBreak: return "Return to your session"
        case .goalCheck: return "Finish your check-in"
        case .results: return "View your results"
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 7) {
                Image(systemName: "lock.fill").foregroundStyle(Theme.Colour.testBadgeFg)
                Text("LockedIN").font(.system(size: 19, weight: .heavy, design: .rounded))
            }
            Spacer()
            Button { destination = .world } label: {
                HStack(spacing: 5) {
                    PixelIconView(icon: .coin, size: 15, tint: Theme.Colour.testBadgeFg)
                    Text(appStore.world.recoveryIssue == nil ? "\(progression.coins)" : "—").monospacedDigit().font(.subheadline.weight(.semibold))
                }
                .padding(.horizontal, 12).padding(.vertical, 9)
                .frame(minWidth: 44, minHeight: 44)
                .background(Theme.Colour.surface, in: Capsule())
            }
            .accessibilityLabel(appStore.world.recoveryIssue == nil ? "\(progression.coins) coins. View progress" : "Saved world unavailable. View details")
            Menu {
                Button("Your progress", systemImage: "chart.bar") { destination = .world }
                Button("Test commitment demo", systemImage: "flask") { destination = .contract }
                    .disabled(appStore.studySession.current != nil || appStore.studySession.recoveryIssue != nil || appStore.world.recoveryIssue != nil)
            } label: {
                Image(systemName: "ellipsis").font(.system(size: 18, weight: .bold)).frame(width: 44, height: 44)
            }
            .accessibilityLabel("More options")
        }
        .buttonStyle(.plain)
    }

    private var welcome: some View {
        clubLayout {
            AvatarPortraitView(appearance: appStore.userCharacter, size: 62)
                .padding(5)
                .background(Theme.Colour.surfaceMid, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.Colour.cardBorder))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                StudioEyebrow(text: "Welcome to your corner")
                Text(appStore.displayName.isEmpty ? "Make yourself at home." : "Hey, \(appStore.displayName).")
                    .font(.system(size: welcomeSize, weight: .bold, design: .rounded)).tracking(-0.7)
                Text("A little focus. A world of your own.")
                    .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
            }
            Spacer(minLength: 0)
        }
    }

    private var roomCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Your study room").font(.system(.headline, design: .rounded))
                    Text("Built one session at a time")
                        .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
                }
                Spacer()
                Text("LV \(progression.level)")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .accessibilityLabel("Level \(progression.level)")
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(Theme.Colour.accentSoft.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 16).padding(.top, 16)
            PersonalRoomScene(room: appStore.world.state.personalRoom, character: appStore.userStudyCharacter)
                .aspectRatio(RoomLayout.imageSize.width / RoomLayout.imageSize.height, contentMode: .fit)
                .padding(.horizontal, 4)
            roomStatsLayout {
                Label {
                    Text("\(progression.sessionsCompleted) sessions completed")
                } icon: {
                    PixelIconView(icon: .hourglass, size: 13, tint: Theme.Colour.textSecondary)
                }
                Label {
                    Text("\(progression.coins) to spend")
                } icon: {
                    PixelIconView(icon: .coin, size: 13, tint: Theme.Colour.testBadgeFg)
                }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(Theme.Colour.textSecondary)
            .padding(14)
            .background(Theme.Colour.surfaceMid.opacity(0.45))
        }
        .background(Theme.Colour.surface, in: RoundedRectangle(cornerRadius: 20))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.Colour.cardBorder))
    }

    private var roomStatsLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
    }

    private func homeRoute(_ title: String, detail: String, icon: PixelIcon, destination target: Destination) -> some View {
        Button { destination = target } label: {
            HStack(spacing: 10) {
                PixelIconView(icon: icon, size: 25, tint: Theme.Colour.testBadgeFg)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(.subheadline, design: .rounded, weight: .semibold))
                    Text(detail).font(.caption2).foregroundStyle(Theme.Colour.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(13).frame(maxWidth: .infinity, minHeight: 68)
            .background(Theme.Colour.surface, in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(Theme.Colour.cardBorder))
        }.buttonStyle(.plain)
        .disabled(appStore.world.recoveryIssue != nil)
        .accessibilityLabel(title)
        .accessibilityHint(detail)
    }

    private var clubCard: some View {
        Button { destination = .group } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    StudioEyebrow(text: "A little company")
                    Spacer()
                    Text("DEMO").font(.system(.caption2, design: .monospaced, weight: .bold))
                        .padding(.horizontal, 7).padding(.vertical, 4)
                        .background(Theme.Colour.surfaceMid, in: RoundedRectangle(cornerRadius: 5))
                }
                clubLayout {
                    HStack(spacing: -8) {
                        ForEach(Array(CharacterCatalog.all.prefix(3))) { character in
                            AvatarPortraitView(appearance: character.fallback, size: 38)
                        }
                    }
                    .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("The study club").font(.system(.headline, design: .rounded))
                        Text("2–8 seats · simulated companions")
                            .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right").font(.system(size: 14, weight: .semibold))
                }
            }.modifier(StudioCard())
        }.buttonStyle(.plain)
        .accessibilityIdentifier("study.club")
        .disabled(appStore.studySession.recoveryIssue != nil || appStore.world.recoveryIssue != nil)
    }

    private var clubLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
            : AnyLayout(HStackLayout(spacing: 14))
    }

    private var progressCard: some View {
        Button { destination = .world } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    StudioEyebrow(text: "Little by little")
                    Spacer()
                    Image(systemName: "arrow.right").font(.caption)
                }
                Text(progression.focusXP == 0 ? "Your story starts here." : "Look how far you’ve come.").font(.headline)
                ProgressView(value: progression.levelProgress).tint(Theme.Colour.focusGreen)
                    .accessibilityLabel("Progress to level \(progression.level + 1)")
                roomStatsLayout {
                    Text("\(progression.xpIntoLevel) / \(progression.xpForThisLevel) XP to level \(progression.level + 1)")
                    if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                    Text("\(progression.sessionsCompleted) sessions")
                }.font(.caption).foregroundStyle(Theme.Colour.textSecondary)
            }.modifier(StudioCard())
        }.buttonStyle(.plain)
    }
}

#Preview { HomeView().environment(AppStore()) }
