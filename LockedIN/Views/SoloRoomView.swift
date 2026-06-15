import SwiftUI

// MARK: - SoloRoomView — your personal focus room (solo-room.png)
//
// A calm, no-stake solo loop on the real engine. The landing shows your avatar in the
// cozy isometric room ("Your space to focus, plan, and grow.") with a focus-length
// picker; Start runs the real LiveSessionView (solo roster, no opponents) and ends in
// the focus-only reveal (focused minutes + coins, no money card). No-args — reads
// AppStore from the environment so HomeView presents it with `SoloRoomView()`.

struct SoloRoomView: View {

    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Stage { case room, session, results }

    @State private var stage: Stage = .room
    @State private var config: RoomConfig = .solo
    @State private var participants: [SessionParticipant] = []

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()
            switch stage {
            case .room:    landing.transition(stageTransition)
            case .session:
                LiveSessionView(
                    config: config,
                    participants: participants,
                    onFinish: { final in participants = final; go(.results) },
                    onCancel: { go(.room) }
                )
                .transition(stageTransition)
            case .results:
                SettlementResultsView(config: config, participants: participants, onDone: { dismiss() })
                    .transition(stageTransition)
            }
        }
        .statusBarHidden(true)
    }

    // MARK: - Landing

    private var landing: some View {
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
                Text("This is your room")
                    .font(Theme.TypeScale.largeTitle).foregroundStyle(Theme.Colour.textPrimary)
                Text("Your space to focus, plan, and grow.")
                    .font(Theme.TypeScale.body).foregroundStyle(Theme.Colour.textSecondary)
            }

            roomCard

            focusPicker

            Spacer()

            Button { start() } label: {
                Text("Start focus session")
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

    private var roomCard: some View {
        ZStack {
            IsometricRoomView()
            GeometryReader { geo in
                SpriteAvatarView(character: appStore.userStudyCharacter, status: .deepFocus, size: 72)
                    .position(x: geo.size.width * 0.50, y: geo.size.height * 0.56)
            }
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
    }

    private var focusPicker: some View {
        HStack(spacing: Theme.Spacing.sm) {
            lengthChip("25 min", minutes: 25, quick: false)
            lengthChip("50 min", minutes: 50, quick: false)
            lengthChip("Quick 20s", minutes: 25, quick: true)
        }
    }

    private func lengthChip(_ label: String, minutes: Int, quick: Bool) -> some View {
        let isSelected = config.quickDemo == quick && (quick || config.focusMinutes == minutes)
        return Button {
            config.focusMinutes = minutes
            config.quickDemo = quick
        } label: {
            Text(label)
                .font(Theme.TypeScale.captionBold)
                .foregroundStyle(isSelected ? Theme.Colour.buttonText : Theme.Colour.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
                .background(isSelected ? Theme.Colour.buttonFill : Theme.Colour.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .strokeBorder(isSelected ? Theme.Colour.accent : Theme.Colour.cardBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Flow

    private func start() {
        participants = SessionParticipant.makeSolo(
            userCharacter: appStore.userStudyCharacter, userName: appStore.displayName
        )
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
}

#Preview("Solo room") {
    SoloRoomView().environment(AppStore())
}
