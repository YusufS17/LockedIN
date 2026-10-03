import SwiftUI

struct HomeView: View {
    enum Destination: String, Identifiable {
        case solo, group, world, avatar, decorate, contract
        var id: String { rawValue }
    }
    @Environment(AppStore.self) private var appStore
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
                welcome
                roomCard
                HStack(spacing: 12) {
                    homeRoute("Edit avatar", detail: "Hair, clothes & you", icon: .shirt, destination: .avatar)
                    homeRoute("Decorate", detail: "Make room for you", icon: .house, destination: .decorate)
                }
                clubCard
                progressCard
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
                        Image(systemName: "play.fill").font(.system(size: 12))
                        Text(studyActionTitle)
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(StudioButtonStyle(primary: true))
                .accessibilityIdentifier("study.start")
                .disabled(appStore.studySession.recoveryIssue != nil)
                Text(appStore.studySession.current?.config.subject ?? "Your pace. Your space.").font(.system(size: 11)).foregroundStyle(Theme.Colour.textSecondary)
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
                    Text("\(progression.coins)").monospacedDigit().font(.subheadline.weight(.semibold))
                }
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(Theme.Colour.surface, in: Capsule())
            }
            .accessibilityLabel("\(progression.coins) coins. View progress")
            Menu {
                Button("Your progress", systemImage: "chart.bar") { destination = .world }
                Button("Test commitment demo", systemImage: "flask") { destination = .contract }
                    .disabled(appStore.studySession.current != nil || appStore.studySession.recoveryIssue != nil)
            } label: {
                Image(systemName: "ellipsis").font(.system(size: 18, weight: .bold)).frame(width: 44, height: 44)
            }
            .accessibilityLabel("More options")
        }
        .buttonStyle(.plain)
    }

    private var welcome: some View {
        HStack(spacing: 14) {
            AvatarPortraitView(appearance: appStore.userCharacter, size: 62)
                .padding(5)
                .background(Theme.Colour.surfaceMid, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.Colour.cardBorder))
            VStack(alignment: .leading, spacing: 4) {
                StudioEyebrow(text: "Welcome to your corner")
                Text(appStore.displayName.isEmpty ? "Make yourself at home." : "Hey, \(appStore.displayName).")
                    .font(.system(size: 27, weight: .bold, design: .rounded)).tracking(-0.7)
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
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(Theme.Colour.accentSoft.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 16).padding(.top, 16)
            PersonalRoomScene(room: appStore.world.state.personalRoom, character: appStore.userStudyCharacter)
                .aspectRatio(RoomLayout.imageSize.width / RoomLayout.imageSize.height, contentMode: .fit)
                .padding(.horizontal, 4)
            HStack(spacing: 6) {
                PixelIconView(icon: .hourglass, size: 13, tint: Theme.Colour.textSecondary)
                Text("\(progression.sessionsCompleted) sessions completed")
                Spacer()
                PixelIconView(icon: .coin, size: 13, tint: Theme.Colour.testBadgeFg)
                Text("\(progression.coins) to spend")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Theme.Colour.textSecondary)
            .padding(14)
            .background(Theme.Colour.surfaceMid.opacity(0.45))
        }
        .background(Theme.Colour.surface, in: RoundedRectangle(cornerRadius: 20))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.Colour.cardBorder))
    }

    private func homeRoute(_ title: String, detail: String, icon: PixelIcon, destination target: Destination) -> some View {
        Button { destination = target } label: {
            HStack(spacing: 10) {
                PixelIconView(icon: icon, size: 25, tint: Theme.Colour.testBadgeFg)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 14, weight: .semibold, design: .rounded))
                    Text(detail).font(.system(size: 10)).foregroundStyle(Theme.Colour.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(13).frame(maxWidth: .infinity, minHeight: 68)
            .background(Theme.Colour.surface, in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(Theme.Colour.cardBorder))
        }.buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var clubCard: some View {
        Button { destination = .group } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    StudioEyebrow(text: "A little company")
                    Spacer()
                    Text("DEMO").font(.system(size: 9, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 7).padding(.vertical, 4)
                        .background(Theme.Colour.surfaceMid, in: RoundedRectangle(cornerRadius: 5))
                }
                HStack(spacing: 14) {
                    HStack(spacing: -8) {
                        ForEach(Array(CharacterCatalog.all.prefix(3))) { character in
                            AvatarPortraitView(appearance: character.fallback, size: 38)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("The study club").font(.system(.headline, design: .rounded))
                        Text("2–8 seats · simulated companions")
                            .font(.system(size: 11)).foregroundStyle(Theme.Colour.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right").font(.system(size: 14, weight: .semibold))
                }
            }.modifier(StudioCard())
        }.buttonStyle(.plain)
        .accessibilityIdentifier("study.club")
        .disabled(appStore.studySession.recoveryIssue != nil)
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
                HStack {
                    Text("\(progression.xpIntoLevel) / \(progression.xpForThisLevel) XP to level \(progression.level + 1)")
                    Spacer()
                    Text("\(progression.sessionsCompleted) sessions")
                }.font(.system(size: 11)).foregroundStyle(Theme.Colour.textSecondary)
            }.modifier(StudioCard())
        }.buttonStyle(.plain)
    }
}

#Preview { HomeView().environment(AppStore()) }
