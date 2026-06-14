import SwiftUI

// MARK: - LiveSessionView — the live focus session (real engine)
//
// Runs a real countdown over `config.sessionSeconds` (Swift Concurrency tick, no
// Combine), shows the room's frozen contract clock, an aggregate focus signal, and a
// live participant row driven by `SpriteAvatarView`. Behaviour is deterministic
// (SES-04): scripted "crackers" (anyone whose distractions exceed the limit) flip to
// `.distracted` partway through. Pause/resume holds the clock; the honest "End
// session" exit and the natural timeout both route to `onFinish(roster)` exactly once.

struct LiveSessionView: View {

    let config: RoomConfig
    var onFinish: ([SessionParticipant]) -> Void   // session ended → settle these participants
    var onCancel: () -> Void                        // backed out before locking in

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var roster: [SessionParticipant]
    @State private var remaining: Int
    @State private var running = true
    @State private var distractionEvents = 0
    @State private var finished = false

    init(config: RoomConfig,
         participants: [SessionParticipant],
         onFinish: @escaping ([SessionParticipant]) -> Void,
         onCancel: @escaping () -> Void) {
        self.config = config
        self.onFinish = onFinish
        self.onCancel = onCancel
        _roster = State(initialValue: participants)
        _remaining = State(initialValue: config.sessionSeconds)
    }

    private var total: Int { max(1, config.sessionSeconds) }
    private var elapsed: Int { total - remaining }
    private var clock: String { String(format: "%d:%02d", remaining / 60, remaining % 60) }
    private var progress: Double { Double(elapsed) / Double(total) }

    private var focusedCount: Int {
        roster.filter { $0.status == .focused || $0.status == .deepFocus }.count
    }

    /// Participants scripted to crack (exceed the distraction limit) — flipped live.
    private var crackerIDs: Set<UUID> {
        Set(roster.filter { $0.distractions > config.distractionLimit }.map(\.id))
    }
    /// When a cracker visibly breaks: just past the contract's midpoint.
    private var crackMoment: Int { max(2, Int(Double(total) * 0.45)) }

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()
            content
        }
        .statusBarHidden(true)
        .task { await runClock() }
    }

    private var content: some View {
        VStack(spacing: Theme.Spacing.lg) {
            header
            Spacer(minLength: 0)
            ring
            aggregateSignal
            participantRow
            Spacer(minLength: 0)
            controls
        }
        .padding(Theme.Spacing.lg)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(config.roomName)
                .font(Theme.TypeScale.title2).foregroundStyle(Theme.Colour.textPrimary)
                .multilineTextAlignment(.center)
            HStack(spacing: Theme.Spacing.sm) {
                Text(config.subject)
                    .font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                Text("·").foregroundStyle(Theme.Colour.textSecondary)
                MoneyLabel(config.stakePence, compact: true)
                Text("each on the line")
                    .font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
            }
        }
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Ring

    private var ring: some View {
        ZStack {
            Circle().stroke(Theme.Colour.cardBorder, lineWidth: 14)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Theme.Colour.accent, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: progress)
            VStack(spacing: Theme.Spacing.xs) {
                Text(clock)
                    .font(.system(size: 60, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.Colour.textPrimary)
                    .monospacedDigit()
                Text(running ? "Locked in" : "Paused")
                    .font(Theme.TypeScale.caption)
                    .foregroundStyle(running ? Theme.Colour.textSecondary : Theme.Colour.forfeitRed)
            }
        }
        .frame(width: 240, height: 240)
    }

    // MARK: - Aggregate signal

    private var aggregateSignal: some View {
        let distractionLabel = distractionEvents == 1 ? "1 distraction" : "\(distractionEvents) distractions"
        return Text("\(focusedCount) focused · \(distractionLabel)")
            .font(Theme.TypeScale.headline)
            .foregroundStyle(Theme.Colour.textPrimary)
    }

    // MARK: - Participants

    private var participantRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: Theme.Spacing.lg) {
                ForEach(roster) { p in
                    VStack(spacing: Theme.Spacing.xs) {
                        SpriteAvatarView(character: p.character, status: p.status,
                                         size: 64, showStatusBadge: true)
                        Text(p.isUser ? "You" : firstName(p.displayName))
                            .font(Theme.TypeScale.captionBold)
                            .foregroundStyle(Theme.Colour.textPrimary)
                        Text(p.status.label)
                            .font(Theme.TypeScale.caption)
                            .foregroundStyle(p.status == .distracted ? Theme.Colour.forfeitRed
                                                                      : Theme.Colour.textSecondary)
                    }
                    .frame(width: 84)
                }
            }
            .padding(.horizontal, Theme.Spacing.xs)
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: Theme.Spacing.md) {
            Button {
                running.toggle()
            } label: {
                Label(running ? "Pause" : "Resume", systemImage: running ? "pause.fill" : "play.fill")
                    .font(Theme.TypeScale.headline)
                    .foregroundStyle(Theme.Colour.buttonText)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colour.buttonFill)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
            }

            // Honest emergency exit — settles whatever's true right now (no deceptive copy).
            Button("End session now") { finish() }
                .font(Theme.TypeScale.caption)
                .foregroundStyle(Theme.Colour.forfeitRed)
        }
    }

    // MARK: - Clock loop (Swift Concurrency — no Combine)

    private func runClock() async {
        while remaining > 0 && !finished {
            try? await Task.sleep(for: .seconds(1))
            guard running, !finished else { continue }
            remaining -= 1
            applyChoreography()
        }
        if remaining == 0 { finish() }
    }

    /// Deterministic live state: crackers flip to `.distracted` at the crack moment.
    private func applyChoreography() {
        guard elapsed >= crackMoment else { return }
        for i in roster.indices where crackerIDs.contains(roster[i].id) && roster[i].status != .distracted {
            roster[i].status = .distracted
            distractionEvents += 1
        }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        running = false
        onFinish(roster)
    }

    private func firstName(_ name: String) -> String {
        name.split(separator: " ").first.map(String.init) ?? name
    }
}

#Preview("Live session") {
    LiveSessionView(
        config: .preset,
        participants: SessionParticipant.makeRoster(
            userCharacter: CharacterCatalog.first, userName: "You", config: .preset
        ),
        onFinish: { _ in },
        onCancel: {}
    )
    .environment(AppStore())
}
