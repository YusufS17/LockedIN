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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header
                timerPanel
                LiveRoomScene(participants: roster, room: appStore.world.state.personalRoom,
                              breakingUserIndex: onBreak ? roster.firstIndex(where: { $0.isUser }) : nil)
                    .padding(.horizontal, -14)
                if isGroup { roomRoster }
                goalCard
                sessionDetails
            }
            .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 24)
        }
        .foregroundStyle(Theme.Colour.textPrimary)
        .background(Theme.Colour.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) { controlDock }
        .sheet(isPresented: $showParticipants) { participantSheet }
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

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: isGroup ? "person.2.fill" : "leaf.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.Colour.focusGreen)
                .frame(width: 42, height: 42)
                .background(Theme.Colour.focusGreen.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(isGroup ? config.roomName : "Your focus room")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Text(isGroup ? "Demo room · simulated companions" : "A little time for yourself")
                    .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
            }
            Spacer(minLength: 0)
            Button { showLeave = true } label: {
                Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(Theme.Colour.surface, in: Circle())
                    .overlay(Circle().strokeBorder(Theme.Colour.cardBorder.opacity(0.65)))
            }.accessibilityLabel("Leave session").accessibilityIdentifier("study.leave")
        }
    }

    private var timerPanel: some View {
        VStack(spacing: 10) {
            (dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout(alignment: .center, spacing: 16))) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Image(systemName: onBreak ? "cup.and.saucer.fill" : "hourglass")
                            .fixedSize().accessibilityHidden(true)
                        Text(onBreak ? "ON A BREAK" : "TIME TO FOCUS").tracking(1.5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.Colour.textSecondary)
                    Text(clock).font(.system(size: timerFontSize, weight: .bold, design: .rounded))
                        .monospacedDigit().tracking(-1)
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .accessibilityLabel("\(remaining / 60) minutes, \(remaining % 60) seconds remaining")
                }
                Spacer(minLength: 0)
                VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 6) {
                    Label(onBreak ? "Timer paused" : config.subject, systemImage: onBreak ? "pause.circle" : "book.closed")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.Colour.focusGreen)
                    Text(onBreak ? "Come back when you’re ready." : config.goal)
                        .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 3)
                        .multilineTextAlignment(dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
                }
            }
            ProgressView(value: min(1, max(0, 1 - Double(remaining) / session.clock.duration)))
                .tint(onBreak ? Theme.Colour.accent : Theme.Colour.focusGreen)
                .accessibilityLabel("Session progress")
        }
        .padding(16)
        .background(Theme.Colour.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.Colour.cardBorder))
        .background(RoundedRectangle(cornerRadius: 18)
            .fill(Theme.Colour.cardBorder.opacity(0.35)).offset(y: 3))
    }

    private var roomRoster: some View {
        Button { showParticipants = true } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("CLUB MEMBERS").font(.caption2.weight(.bold)).tracking(1.5)
                    Spacer()
                    Text("Goals & people").font(.caption.weight(.semibold))
                    Image(systemName: "chevron.right").font(.caption2.weight(.bold))
                }.foregroundStyle(Theme.Colour.textSecondary)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2), spacing: 12) {
                    ForEach(Array(roster.prefix(4))) { person in
                        HStack(spacing: 8) {
                            AvatarPortraitView(appearance: person.character.fallback, size: 34)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(person.isUser ? "You" : person.displayName)
                                    .font(.subheadline.weight(.semibold))
                                Label(person.status.label, systemImage: person.status.symbolName ?? "circle.fill")
                                    .font(.caption).foregroundStyle(statusInk(person.status))
                            }
                        }
                    }
                }
                Text(roster.count > 4 ? "First 4 of \(roster.count) · Simulated companions · View all" : "Simulated companions · \(focusedCount)/\(roster.count) focusing")
                    .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colour.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.Colour.cardBorder.opacity(0.7)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("study.participants")
        .accessibilityLabel("In the room, \(roster.count) people, \(focusedCount) focusing. Everyone’s goals. Simulated companions.")
    }

    private var sessionDetails: some View {
        VStack(spacing: 12) {
            if let building = appStore.world.state.activeBuilding {
                HStack(spacing: 10) {
                    Image(systemName: building.type.symbol).foregroundStyle(Theme.Colour.focusGreen)
                    Text("Growing your \(building.type.title)").font(.caption.weight(.medium))
                    Spacer(minLength: 0)
                    ProgressView(value: building.progress).tint(Theme.Colour.focusGreen).frame(width: 64)
                }
            }
            (dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6)) : AnyLayout(HStackLayout(spacing: 6))) {
                Image(systemName: "leaf")
                Text(config.competitive ? "Competitive demo" : "Supportive session")
                Spacer()
                Text("\(breaksUsed)/\(config.breakAllowance) breaks used")
            }.font(.caption)
            Text(isGroup ? "Companions are simulated. Your timer keeps running outside the app; other app use is not tracked." : "Your timer keeps running outside the app. Breaks and interruptions are self-reported; other app use is not tracked.")
                .font(.caption).fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }.foregroundStyle(Theme.Colour.textSecondary)
    }

    private func statusInk(_ status: AvatarStatus) -> Color {
        switch status {
        case .focused, .finished: return Theme.Colour.focusGreen
        case .deepFocus: return Theme.Colour.deepFocusBlue
        case .distracted: return Theme.Colour.forfeitRed
        case .idle, .onBreak: return Theme.Colour.textSecondary
        }
    }

    private var controlDock: some View {
        VStack(spacing: 8) {
            (dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))) {
                Button {
                    session.reportInterruption(at: Date())
                    onCheckpoint(session)
                    if !session.isRunning { onFinish(session.participants) }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: "arrow.uturn.backward").font(.system(size: 15, weight: .semibold))
                        Text("Interrupted").font(.caption2.weight(.semibold))
                    }
                    .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : 76, minHeight: 50)
                    .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 8 : 0)
                    .background(Theme.Colour.surface, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colour.cardBorder))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("I got interrupted, \(session.user?.distractions ?? 0) reported")
                .accessibilityIdentifier("study.interruption")
                .disabled(onBreak)
                Button(action: toggleBreak) {
                    Label(onBreak ? "Back to focus" : "Take a break", systemImage: onBreak ? "play.fill" : "cup.and.saucer")
                }
                .buttonStyle(StudioButtonStyle(primary: true))
                .accessibilityIdentifier("study.break")
                .disabled(!onBreak && breaksUsed >= config.breakAllowance)
            }
            if !onBreak && breaksUsed >= config.breakAllowance {
                Text("All planned breaks used. You can still report an interruption or leave the session.")
                    .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 8)
        .background(Theme.Colour.background)
        .overlay(alignment: .top) { Rectangle().fill(Theme.Colour.cardBorder.opacity(0.5)).frame(height: 1) }
    }

    private var goalCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "book.closed").font(.system(size: 21)).foregroundStyle(Theme.Colour.focusGreen)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 6) {
                StudioEyebrow(text: config.subject.isEmpty ? "Your focus" : config.subject)
                Text(config.goal.isEmpty ? "A little closer to where you want to be." : config.goal)
                    .font(.subheadline.weight(.medium)).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(StudioCard())
    }

    private var participantSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Different goals. Shared quiet.")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                        Text("Your companions are simulated. These are their demo study goals; your end-of-session check-in stays private.")
                            .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
                    }.padding(.vertical, 8)
                    ForEach(roster) { person in
                        VStack(alignment: .leading, spacing: 12) {
                            (dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))) {
                                AvatarPortraitView(appearance: person.character.fallback, size: 42)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(person.isUser ? "You" : person.displayName)
                                        .font(.system(.headline, design: .rounded, weight: .bold))
                                    Text(person.isUser ? "Your study goal" : "Simulated companion")
                                        .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
                                }
                                Spacer(minLength: 0)
                                Label(person.status.label, systemImage: person.status.symbolName ?? "circle.fill")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(statusInk(person.status))
                            }
                            if let intent = person.studyIntent {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(intent.subject.uppercased())
                                        .font(.caption2.weight(.bold)).tracking(1)
                                        .foregroundStyle(Theme.Colour.textSecondary)
                                    Text(intent.goal).font(.subheadline.weight(.medium))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Theme.Colour.background, in: RoundedRectangle(cornerRadius: 10))
                            } else {
                                Text("No shared study goal").font(.caption).foregroundStyle(Theme.Colour.textSecondary)
                            }
                        }
                        .padding(14)
                        .background(Theme.Colour.surface, in: RoundedRectangle(cornerRadius: 17))
                        .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(Theme.Colour.cardBorder.opacity(0.7)))
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("study.person.\(person.isUser ? "you" : person.character.id)")
                    }
                }.padding(20)
            }
            .background(Theme.Colour.background)
            .navigationTitle("In the room").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showParticipants = false }.accessibilityIdentifier("study.participants.done") } }
        }
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
