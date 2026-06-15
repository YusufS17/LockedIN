import SwiftUI

// MARK: - LiveSessionView — the live study room (Demo09)
//
// The room as drawn in the mockup: brand masthead, a big "TIME REMAINING" clock with a
// slim progress bar, the editable room title + member count, BREAKS / DISTRACTIONS stat
// tiles, the cozy isometric room (code-drawn IsometricRoomView) with participants placed
// at their desks under floating status labels, a live participant list, and the Leave /
// Take a break / Room chat toolbar.
//
// The clock is a Swift-Concurrency tick (no Combine). Behaviour is deterministic
// (SES-04): high-focus members study in Deep focus, the scripted cracker (over the
// distraction limit) breaks to Distracted past the midpoint, and "Take a break" spends
// the contract's break allowance. The honest Leave exit and the natural timeout both
// settle the roster via onFinish exactly once.

struct LiveSessionView: View {

    let config: RoomConfig
    var onFinish: ([SessionParticipant]) -> Void
    var onCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppStore.self) private var appStore

    @State private var roster: [SessionParticipant]
    @State private var remaining: Int
    @State private var running = true
    @State private var distractionEvents = 0
    @State private var breaksUsed = 0
    @State private var onBreak = false
    @State private var finished = false

    init(config: RoomConfig,
         participants: [SessionParticipant],
         onFinish: @escaping ([SessionParticipant]) -> Void,
         onCancel: @escaping () -> Void) {
        self.config = config
        self.onFinish = onFinish
        self.onCancel = onCancel
        // Seed live "vibes": top focusers start in Deep focus; the cracker stays Focused
        // until it breaks. Deterministic — derived from each participant's scripted traits.
        var seeded = participants
        for i in seeded.indices {
            let p = seeded[i]
            let isCracker = p.distractions > config.distractionLimit
            seeded[i].status = (!isCracker && p.focusPct >= 95) ? .deepFocus : .focused
        }
        _roster = State(initialValue: seeded)
        _remaining = State(initialValue: config.sessionSeconds)
    }

    private var total: Int { max(1, config.sessionSeconds) }
    private var elapsed: Int { total - remaining }
    private var clock: String { String(format: "%02d:%02d", remaining / 60, remaining % 60) }
    private var progress: Double { Double(elapsed) / Double(total) }

    private var crackerIDs: Set<UUID> {
        Set(roster.filter { $0.distractions > config.distractionLimit }.map(\.id))
    }
    private var crackMoment: Int { max(2, Int(Double(total) * 0.45)) }

    // Floor slots (fractions of the room scene) for up to 4 desks.
    private let slots: [CGPoint] = [
        CGPoint(x: 0.30, y: 0.50),
        CGPoint(x: 0.52, y: 0.43),
        CGPoint(x: 0.70, y: 0.52),
        CGPoint(x: 0.50, y: 0.63)
    ]

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.md) {
                BrandLockHeader().padding(.top, Theme.Spacing.sm)
                clockBlock
                titleBlock
                statTiles
                roomScene
                participantList
                Spacer(minLength: 0)
                toolbar
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.md)
        }
        .statusBarHidden(true)
        .task { await runClock() }
    }

    // MARK: - Clock

    private var clockBlock: some View {
        VStack(spacing: 4) {
            Label("TIME REMAINING", systemImage: "timer")
                .font(Theme.TypeScale.captionBold)
                .foregroundStyle(Theme.Colour.textSecondary)
            Text(clock)
                .font(.system(size: 52, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.Colour.textPrimary)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(onBreak ? "On a break — clock paused" : (running ? "Focus together. Finish stronger." : "Paused"))
                .font(Theme.TypeScale.caption)
                .foregroundStyle(onBreak || !running ? Theme.Colour.forfeitRed : Theme.Colour.textSecondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.Colour.surfaceMid).frame(height: 6)
                    Capsule().fill(Theme.Colour.accent)
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: progress)
                }
            }
            .frame(height: 6)
            .padding(.top, 2)
        }
    }

    // MARK: - Title + members

    private var titleBlock: some View {
        VStack(spacing: 2) {
            HStack(spacing: Theme.Spacing.xs) {
                Text(config.roomName)
                    .font(Theme.TypeScale.title2)
                    .foregroundStyle(Theme.Colour.textPrimary)
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.Colour.textSecondary)
            }
            Text("\(roster.count) members · \(config.subject)")
                .font(Theme.TypeScale.caption)
                .foregroundStyle(Theme.Colour.textSecondary)
        }
    }

    // MARK: - Stat tiles

    private var statTiles: some View {
        HStack(spacing: Theme.Spacing.md) {
            miniStat("cup.and.saucer.fill", "BREAKS", "\(breaksUsed)/\(config.breakAllowance)")
            miniStat("exclamationmark.triangle.fill", "DISTRACTIONS", "\(distractionEvents)")
            miniStat("flame.fill", "FOCUSED", "\(roster.filter { $0.status == .focused || $0.status == .deepFocus }.count)")
        }
    }

    private func miniStat(_ icon: String, _ label: String, _ value: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.Colour.accent)
            VStack(alignment: .leading, spacing: 0) {
                Text(label).font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.Colour.textSecondary)
                Text(value).font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.textPrimary).monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colour.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
    }

    // MARK: - Room scene (isometric room + placed avatars)

    private var roomScene: some View {
        GeometryReader { geo in
            ZStack {
                IsometricRoomView(room: appStore.world.state.personalRoom)
                ForEach(Array(roster.enumerated()), id: \.element.id) { i, p in
                    placedAvatar(p, at: slots[i % slots.count], in: geo.size)
                }
            }
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
    }

    private func placedAvatar(_ p: SessionParticipant, at slot: CGPoint, in size: CGSize) -> some View {
        VStack(spacing: 2) {
            statusPill(p.status)
            SpriteAvatarView(character: p.character, status: p.status, size: 52, showStatusBadge: false)
        }
        .position(x: size.width * slot.x, y: size.height * slot.y)
    }

    private func statusPill(_ status: AvatarStatus) -> some View {
        Text(status.label)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(status.ringColour))
            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
    }

    // MARK: - Participant list

    private var participantList: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ForEach(roster) { p in
                HStack(spacing: Theme.Spacing.sm) {
                    SpriteAvatarView(character: p.character, status: p.status, size: 32, showStatusBadge: false, animated: false)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(p.isUser ? "You" : firstName(p.displayName))
                            .font(Theme.TypeScale.captionBold)
                            .foregroundStyle(Theme.Colour.textPrimary)
                        Text(p.status.label)
                            .font(Theme.TypeScale.caption)
                            .foregroundStyle(p.status == .distracted ? Theme.Colour.forfeitRed : Theme.Colour.textSecondary)
                    }
                    Spacer()
                    signalBars(for: p.status)
                    Text(clock)
                        .font(Theme.TypeScale.caption)
                        .foregroundStyle(Theme.Colour.textSecondary)
                        .monospacedDigit()
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func signalBars(for status: AvatarStatus) -> some View {
        let strength: Int = {
            switch status {
            case .deepFocus: return 3
            case .focused:   return 2
            case .onBreak:   return 1
            default:         return 0   // distracted / idle / finished
            }
        }()
        return HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(i < strength ? status.ringColour : Theme.Colour.surfaceMid)
                    .frame(width: 3, height: CGFloat(6 + i * 4))
            }
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            toolButton("rectangle.portrait.and.arrow.right", "Leave", tint: Theme.Colour.forfeitRed) { finish() }
            toolButton("cup.and.saucer.fill", onBreak ? "Resume" : "Take a break",
                       tint: Theme.Colour.textPrimary,
                       disabled: !onBreak && breaksUsed >= config.breakAllowance) { toggleBreak() }
            toolButton("bubble.left.and.bubble.right.fill", "Room chat",
                       tint: Theme.Colour.textSecondary, disabled: true) {}
        }
    }

    private func toolButton(_ icon: String, _ label: String, tint: Color,
                            disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 16, weight: .bold))
                Text(label).font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colour.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
        }
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1)
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

    /// Deterministic live state: crackers flip to Distracted at the crack moment.
    private func applyChoreography() {
        guard elapsed >= crackMoment else { return }
        for i in roster.indices where crackerIDs.contains(roster[i].id) && roster[i].status != .distracted {
            roster[i].status = .distracted
            distractionEvents += 1
        }
    }

    // MARK: - Actions

    private func toggleBreak() {
        guard let me = roster.firstIndex(where: { $0.isUser }) else { return }
        if onBreak {
            onBreak = false
            running = true
            roster[me].status = roster[me].focusPct >= 95 ? .deepFocus : .focused
        } else {
            guard breaksUsed < config.breakAllowance else { return }
            breaksUsed += 1
            onBreak = true
            running = false
            roster[me].status = .onBreak
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
