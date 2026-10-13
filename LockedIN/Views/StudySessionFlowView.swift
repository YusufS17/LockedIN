import SwiftUI

/// Solo and demo-club journeys share the same saved session, goal check and results.
struct StudySessionFlowView: View {
    let group: Bool
    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var config: RoomConfig
    @State private var clubSize = 4

    init(group: Bool) {
        self.group = group
        _config = State(initialValue: group ? .groupRoom : .solo)
    }

    var body: some View {
        Group {
            if let session = appStore.studySession.current {
                switch session.phase {
                case .focusing, .onBreak:
                    LiveSessionView(config: session.config, participants: session.participants,
                                    restoredSession: session,
                                    onCheckpoint: { appStore.studySession.checkpoint($0) },
                                    onFinish: { _ in }, onCancel: {})
                        .id(session.id)
                case .goalCheck:
                    goalCheck(session)
                case .results:
                    SettlementResultsView(config: session.config, participants: session.participants) {
                        // Keep the participant UUID and pending outcome if world saving is blocked.
                        if appStore.world.recoveryIssue == nil {
                            appStore.studySession.acknowledgeResults(id: session.id)
                        }
                        dismiss()
                    }
                }
            } else if let issue = appStore.world.recoveryIssue {
                VStack(spacing: 18) {
                    Text("Your saved world needs attention").font(.title2.bold())
                    Text(issue.message)
                    Button("Return home") { dismiss() }.buttonStyle(StudioButtonStyle(primary: true))
                }.padding(24)
            } else {
                StudySetupView(config: $config, clubSize: $clubSize, group: group, onStart: start, onClose: { dismiss() })
            }
        }
        .preferredColorScheme(.light)
    }

    private func start() {
        guard appStore.world.recoveryIssue == nil else { return }
        let roster = group
            ? SessionParticipant.makeRoster(userCharacter: appStore.userStudyCharacter, userName: appStore.displayName, config: config, count: clubSize)
            : SessionParticipant.makeSolo(userCharacter: appStore.userStudyCharacter, userName: appStore.displayName)
        appStore.studySession.begin(config: config, participants: roster)
    }

    private func goalCheck(_ session: ActiveStudySession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                (dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout())) {
                    StudioEyebrow(text: "Session complete")
                    if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                    Label("Private check-in", systemImage: "lock")
                        .font(.caption2).foregroundStyle(Theme.Colour.textSecondary)
                }
                (dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16)) : AnyLayout(HStackLayout(spacing: 16))) {
                    PixelAvatarView(appearance: appStore.userCharacter, status: .finished, size: 108)
                        .frame(width: 94)
                    VStack(alignment: .leading, spacing: 7) {
                        Text("A little closer.")
                            .font(.system(.title, design: .rounded, weight: .bold))
                        Text("You made time for what matters.")
                            .font(.subheadline).foregroundStyle(Theme.Colour.textSecondary)
                    }
                }.padding(.vertical, 8)
                VStack(alignment: .leading, spacing: 10) {
                    StudioEyebrow(text: session.config.subject)
                    Text(session.config.goal).font(.system(.title3, design: .rounded, weight: .semibold))
                    Divider().overlay(Theme.Colour.cardBorder.opacity(0.4))
                    Text("How far did you get?").font(.subheadline.weight(.medium))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .modifier(StudioCard())
                ForEach(ActiveStudySession.GoalReview.allCases, id: \.rawValue) { answer in
                    Button { appStore.studySession.reviewGoal(answer) } label: {
                        HStack {
                            Text(answer.label)
                            Spacer()
                            Image(systemName: answer == .achieved ? "checkmark.circle" : "arrow.right")
                        }
                    }
                        .buttonStyle(StudioButtonStyle(primary: answer == .achieved))
                        .accessibilityIdentifier("study.review.\(answer.rawValue)")
                }
                Label("Only you see this answer. Your earned session reward stays the same.", systemImage: "lock.shield")
                    .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }.padding(24)
        }
        .foregroundStyle(Theme.Colour.textPrimary)
        .background(Theme.Colour.background.ignoresSafeArea())
    }
}
