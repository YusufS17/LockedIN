import SwiftUI

// MARK: - RoomFlowView — the real commitment loop orchestrator
//
// Drives the full spine on the real engine: Set your lock-in (RoomSetupView) → live
// study room (LiveSessionView) → consequence reveal (SettlementResultsView). The user's
// frozen RoomConfig and the deterministic roster (you + Maya/Leo/Sam) thread through all
// three stages; the live session hands its final roster to settlement so the reveal
// reflects what actually happened. No-args by design — reads AppStore from the
// environment so HomeView can present it with `RoomFlowView()`.

struct RoomFlowView: View {

    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Stage { case setup, session, results }

    @State private var stage: Stage = .setup
    @State private var config: RoomConfig = .preset
    @State private var participants: [SessionParticipant] = []

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()

            switch stage {
            case .setup:
                RoomSetupView(
                    onStart: { cfg in beginSession(with: cfg) },
                    onCancel: { dismiss() }
                )
                .transition(stageTransition)

            case .session:
                LiveSessionView(
                    config: config,
                    participants: participants,
                    onFinish: { finalRoster in
                        participants = finalRoster          // carry live outcome into settlement
                        go(.results)
                    },
                    onCancel: { go(.setup) }
                )
                .transition(stageTransition)

            case .results:
                SettlementResultsView(
                    config: config,
                    participants: participants,
                    onDone: { dismiss() }
                )
                .transition(stageTransition)
            }
        }
    }

    // MARK: - Transitions

    private func beginSession(with cfg: RoomConfig) {
        config = cfg
        participants = SessionParticipant.makeRoster(
            userCharacter: appStore.selectedCharacter,
            userName: appStore.displayName,
            config: cfg
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

#Preview("Room flow") {
    RoomFlowView().environment(AppStore())
}
