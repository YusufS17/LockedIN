import SwiftUI

// MARK: - GroupRoomView — drop-in squad room (group-room.png)
//
// "Join a room": a social, no-stake group focus loop on the real engine. The lobby
// previews the squad and the (unstaked) contract; Join runs the real LiveSessionView
// with the deterministic roster (you + Maya/Leo/Sam) and ends in the focus-only reveal
// crowning a Champion (and, competitively, the Biggest Culprit) — no money card. No-args
// — reads AppStore from the environment so HomeView presents it with `GroupRoomView()`.

struct GroupRoomView: View {

    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Stage { case lobby, session, results }

    @State private var stage: Stage = .lobby
    @State private var config: RoomConfig = .groupRoom
    @State private var participants: [SessionParticipant] = []

    private var squad: [SessionParticipant] {
        participants.isEmpty
            ? SessionParticipant.makeRoster(userCharacter: appStore.selectedCharacter,
                                            userName: appStore.displayName, config: config)
            : participants
    }

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()
            switch stage {
            case .lobby:   lobby.transition(stageTransition)
            case .session:
                LiveSessionView(
                    config: config,
                    participants: participants,
                    onFinish: { final in participants = final; go(.results) },
                    onCancel: { go(.lobby) }
                )
                .transition(stageTransition)
            case .results:
                SettlementResultsView(config: config, participants: participants, onDone: { dismiss() })
                    .transition(stageTransition)
            }
        }
        .statusBarHidden(true)
    }

    // MARK: - Lobby

    private var lobby: some View {
        VStack(spacing: Theme.Spacing.lg) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.Colour.textSecondary)
                }
                Spacer()
            }
            BrandLockHeader()

            VStack(spacing: Theme.Spacing.xs) {
                Text("Join a room")
                    .font(Theme.TypeScale.largeTitle).foregroundStyle(Theme.Colour.textPrimary)
                Text(config.roomName)
                    .font(Theme.TypeScale.body).foregroundStyle(Theme.Colour.textSecondary)
            }

            membersCard
            contractCard

            Spacer()

            Button { join() } label: {
                Text("Join room")
                    .font(Theme.TypeScale.headline)
                    .foregroundStyle(Theme.Colour.buttonText)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colour.buttonFill)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
            }
        }
        .padding(Theme.Spacing.lg)
    }

    private var membersCard: some View {
        card {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                cardTitle("\(squad.count) MEMBERS READY")
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(squad) { p in
                        VStack(spacing: 4) {
                            SpriteAvatarView(character: p.character, status: .idle, size: 48)
                            Text(p.isUser ? "You" : firstName(p.displayName))
                                .font(Theme.TypeScale.caption)
                                .foregroundStyle(Theme.Colour.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var contractCard: some View {
        card {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                cardTitle("THE PLAN")
                planRow("clock.fill", "Focus for \(config.focusMinutes) min together")
                planRow("cup.and.saucer.fill", "Up to \(config.breakAllowance) break\(config.breakAllowance == 1 ? "" : "s")")
                planRow("trophy.fill", "Most focused gets crowned Champion")
                Text("Social room · no stake")
                    .font(Theme.TypeScale.caption)
                    .foregroundStyle(Theme.Colour.testBadgeFg)
                    .padding(.top, Theme.Spacing.xs)
            }
        }
    }

    private func planRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon).font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.Colour.accent)
            Text(text).font(Theme.TypeScale.body).foregroundStyle(Theme.Colour.textPrimary)
        }
    }

    // MARK: - Flow

    private func join() {
        participants = squad
        go(.session)
    }

    private func go(_ next: Stage) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) { stage = next }
    }

    private var stageTransition: AnyTransition {
        reduceMotion ? .opacity : .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    // MARK: - Bits

    private func cardTitle(_ text: String) -> some View {
        Text(text).font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.textSecondary)
    }

    private func firstName(_ name: String) -> String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    private func card<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colour.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
    }
}

#Preview("Group room") {
    GroupRoomView().environment(AppStore())
}
