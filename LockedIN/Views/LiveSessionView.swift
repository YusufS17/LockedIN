import SwiftUI

struct LiveSessionView: View {
    let config: RoomConfig
    var onFinish: ([SessionParticipant]) -> Void
    var onCancel: () -> Void
    @Environment(AppStore.self) private var appStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var timerFontSize = 42.0
    @State private var session: ActiveStudySession
    @State private var now = Date()
    @State private var showParticipants = false
    @State private var showLeave = false
    @State private var showDetails = false
    private let onCheckpoint: (ActiveStudySession) -> Void

    init(config: RoomConfig, participants: [SessionParticipant],
         restoredSession: ActiveStudySession? = nil,
         onCheckpoint: @escaping (ActiveStudySession) -> Void = { _ in },
         onFinish: @escaping ([SessionParticipant]) -> Void, onCancel: @escaping () -> Void) {
        self.config = restoredSession?.config ?? config
        self.onFinish = onFinish
        self.onCancel = onCancel
        self.onCheckpoint = onCheckpoint
        _session = State(initialValue: restoredSession ?? ActiveStudySession(config: config, participants: participants))
    }

    private var roster: [SessionParticipant] { session.participants }
    private var remaining: Int { session.clock.remaining(at: now) }
    private var onBreak: Bool { session.phase == .onBreak }
    private var breaksUsed: Int { session.breaksUsed }
    private var clock: String { String(format: "%02d:%02d", remaining / 60, remaining % 60) }
    private var focusedCount: Int { roster.filter { $0.status == .focused || $0.status == .deepFocus }.count }
    private var isGroup: Bool { roster.count > 1 }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibleRoom
            } else {
                immersiveRoom
            }
        }
        .foregroundStyle(FocusApartmentStyle.ink)
        .background(ApartmentNightBackdrop().ignoresSafeArea())
        .preferredColorScheme(.dark)
        .safeAreaInset(edge: .bottom, spacing: 0) { controlDock }
        .sheet(isPresented: $showParticipants) { participantSheet }
        .sheet(isPresented: $showDetails) { detailsSheet }
        .confirmationDialog("Leave this session?", isPresented: $showLeave, titleVisibility: .visible) {
            Button("Leave session", role: .destructive) { finish(leaving: true) }
            Button("Keep focusing", role: .cancel) {}
        } message: {
            Text("This session will be marked as left early.\(config.isStaked ? " Your simulated test stake will be forfeited." : " You can start fresh whenever you’re ready.")")
        }
        .task { await runClock() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { tick() } else { onCheckpoint(session) }
        }
    }

    private var immersiveRoom: some View {
        ZStack(alignment: .top) {
            // The shared backdrop extends behind system chrome. Keep the room
            // and its controls inside the same safe-area proposal.
            LiveRoomScene(participants: roster, room: appStore.world.state.personalRoom,
                          breakingUserIndex: onBreak ? roster.firstIndex(where: { $0.isUser }) : nil,
                          immersive: true)
            VStack(spacing: 10) {
                topControls
                if isGroup { roomRoster.padding(.horizontal, 48) }
            }
            .padding(.horizontal, 16).padding(.top, 10)
        }
    }

    private var accessibleRoom: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                topControls
                LiveRoomScene(participants: roster, room: appStore.world.state.personalRoom,
                              breakingUserIndex: onBreak ? roster.firstIndex(where: { $0.isUser }) : nil)
                if isGroup { roomRoster }
                sessionDetails
            }.padding(20)
        }
    }

    private var topControls: some View {
        HStack(alignment: .top, spacing: 10) {
            Button { showLeave = true } label: {
                Image(systemName: "xmark").font(.subheadline.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(FocusApartmentStyle.panel.opacity(0.96), in: Circle())
                    .overlay(Circle().strokeBorder(FocusApartmentStyle.border))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Leave session").accessibilityIdentifier("study.leave")
            timerPanel
            Button { showDetails = true } label: {
                Image(systemName: "info").font(.subheadline.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(FocusApartmentStyle.panel.opacity(0.96), in: Circle())
                    .overlay(Circle().strokeBorder(FocusApartmentStyle.border))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Session details").accessibilityIdentifier("study.details")
        }
    }

    private var timerPanel: some View {
        VStack(spacing: 4) {
            Text(clock).font(.system(size: timerFontSize, weight: .bold, design: .rounded))
                .monospacedDigit().tracking(-1)
                .lineLimit(1).minimumScaleFactor(0.55)
                .accessibilityLabel("\(remaining / 60) minutes, \(remaining % 60) seconds remaining")
                .accessibilityIdentifier("study.timer")
            Text(onBreak ? "Timer paused" : config.subject)
                .font(.subheadline.weight(.semibold))
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(FocusApartmentStyle.panel.opacity(0.97), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(FocusApartmentStyle.border))
    }

    private var roomRoster: some View {
        Button { showParticipants = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "person.2")
                Text("\(roster.count) people · Demo room")
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption)
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 14).padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(FocusApartmentStyle.panel.opacity(0.97), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(FocusApartmentStyle.border))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("study.participants")
        .accessibilityLabel("In the room, \(roster.count) people, \(focusedCount) focusing. Everyone’s goals. Simulated companions.")
    }

    private var sessionDetails: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(config.subject).font(.headline).accessibilityAddTraits(.isHeader)
            Text(config.goal).font(.body).fixedSize(horizontal: false, vertical: true)
            Divider().overlay(FocusApartmentStyle.border)
            Text("\(breaksUsed)/\(config.breakAllowance) planned breaks used")
                .font(.subheadline).fixedSize(horizontal: false, vertical: true)
            if let building = appStore.world.state.activeBuilding {
                Text("Study destination: \(building.type.title)")
                    .font(.subheadline).fixedSize(horizontal: false, vertical: true)
            }
            if config.competitive { Text("Competitive demo").font(.subheadline) }
            Text("Your timer continues outside the app. Breaks and interruptions are self-reported; other app use is not tracked or blocked.")
                .font(.body).fixedSize(horizontal: false, vertical: true)
            if isGroup {
                Text("Companions and their study goals are simulated. Your end-of-session check-in stays private.")
                    .font(.body).fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(FocusApartmentStyle.panel, in: RoundedRectangle(cornerRadius: 16))
    }

    private var detailsSheet: some View {
        NavigationStack {
            ScrollView { sessionDetails.padding(20) }
                .background(FocusApartmentStyle.background)
                .foregroundStyle(FocusApartmentStyle.ink)
                .navigationTitle("Session details").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showDetails = false } } }
        }
        .preferredColorScheme(.dark)
    }

    private var controlDock: some View {
        VStack(spacing: 8) {
            (dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))) {
                Button {
                    session.reportInterruption(at: Date())
                    onCheckpoint(session)
                    if !session.isRunning { onFinish(session.participants) }
                } label: {
                    Text("Interrupted").frame(maxWidth: .infinity).contentShape(Rectangle())
                }
                .buttonStyle(FocusApartmentButtonStyle())
                .accessibilityLabel("I got interrupted, \(session.user?.distractions ?? 0) reported")
                .accessibilityIdentifier("study.interruption")
                .disabled(onBreak)
                Button(action: toggleBreak) {
                    Text(onBreak ? "Back to focus" : "Take a break").frame(maxWidth: .infinity).contentShape(Rectangle())
                }
                .buttonStyle(FocusApartmentButtonStyle(primary: true))
                .accessibilityIdentifier("study.break")
                .disabled(!onBreak && breaksUsed >= config.breakAllowance)
            }
            if !onBreak && breaksUsed >= config.breakAllowance {
                Text("Planned breaks used")
                    .font(.caption).foregroundStyle(FocusApartmentStyle.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 8)
        .background(FocusApartmentStyle.background.opacity(0.82))
    }

    private func statusInk(_ status: AvatarStatus) -> Color {
        switch status {
        case .focused, .finished: return FocusApartmentStyle.amber
        case .deepFocus: return Color(red: 0.56, green: 0.72, blue: 0.94)
        case .distracted: return Color(red: 0.96, green: 0.56, blue: 0.43)
        case .idle, .onBreak: return FocusApartmentStyle.secondary
        }
    }

    private var participantSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Simulated companions · check-ins stay private")
                        .font(.caption).foregroundStyle(FocusApartmentStyle.secondary)
                    ForEach(roster) { person in
                        VStack(alignment: .leading, spacing: 12) {
                            (dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))) {
                                AvatarPortraitView(appearance: person.character.fallback, size: 42)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(person.isUser ? "You" : person.displayName)
                                        .font(.system(.headline, design: .rounded, weight: .bold))
                                    Text(person.isUser ? "Your study goal" : "Simulated companion")
                                        .font(.caption).foregroundStyle(FocusApartmentStyle.secondary)
                                }
                                if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
                                Text(person.status.label).font(.caption.weight(.medium))
                                    .foregroundStyle(statusInk(person.status))
                            }
                            if let intent = person.studyIntent {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(intent.subject).font(.caption.weight(.bold))
                                        .foregroundStyle(FocusApartmentStyle.secondary)
                                    Text(intent.goal).font(.subheadline.weight(.medium))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text("No shared study goal").font(.caption).foregroundStyle(FocusApartmentStyle.secondary)
                            }
                        }
                        .padding(14)
                        .background(FocusApartmentStyle.panel, in: RoundedRectangle(cornerRadius: 17))
                        .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(FocusApartmentStyle.border))
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("study.person.\(person.isUser ? "you" : person.character.id)")
                    }
                }.padding(20)
            }
            .background(FocusApartmentStyle.background)
            .foregroundStyle(FocusApartmentStyle.ink)
            .navigationTitle("In the room").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showParticipants = false }.accessibilityIdentifier("study.participants.done") } }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
    }

    private func runClock() async {
        while session.isRunning && !Task.isCancelled {
            tick()
            do { try await Task.sleep(for: .seconds(1)) } catch { return }
        }
    }

    private func tick() {
        guard session.isRunning else { return }
        now = Date()
        let before = session
        session.update(at: now)
        if before != session { onCheckpoint(session) }
        if !session.isRunning { onFinish(session.participants) }
    }

    private func toggleBreak() {
        now = Date()
        session.toggleBreak(at: now)
        onCheckpoint(session)
        if !session.isRunning { onFinish(session.participants) }
    }

    private func finish(leaving: Bool) {
        guard session.isRunning else { return }
        now = Date()
        session.finish(leaving: leaving, at: now)
        onCheckpoint(session)
        onFinish(session.participants)
    }

}

#Preview {
    LiveSessionView(config: .solo, participants: SessionParticipant.makeSolo(userCharacter: CharacterCatalog.first, userName: "You"), onFinish: { _ in }, onCancel: {})
        .environment(AppStore())
}
