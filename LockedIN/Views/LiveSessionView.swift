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
    @State private var showParticipants = false

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

    /// Where an avatar stands when on an approved break (the break corner).
    private let breakSlot = CGPoint(x: 0.86, y: 0.30)

    // MARK: - Live group status (derived)

    private var focusedCount: Int { roster.filter { $0.status == .focused || $0.status == .deepFocus }.count }
    private var breakCount: Int { roster.filter { $0.status == .onBreak }.count }
    private var distractedCount: Int { roster.filter { $0.status == .distracted }.count }
    /// Members still perfectly LockedIN (not distracted, not on break, not left).
    private var stillLockedIn: Int { roster.filter { $0.status == .focused || $0.status == .deepFocus || $0.status == .finished }.count }
    private var modeLabel: String { config.competitive ? "Competitive mode" : "Supportive mode" }

    private func focusedMinutes(_ p: SessionParticipant) -> Int {
        Int((Double(config.focusMinutes) * Double(p.focusPct) / 100).rounded())
    }
    private func warningsRemaining(_ p: SessionParticipant) -> Int {
        max(0, config.distractionLimit - p.distractions)
    }

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.sm) {
                BrandLockHeader().padding(.top, Theme.Spacing.sm)
                clockBlock
                titleBlock
                groupStatusBar
                roomScene                       // hero — fills remaining space
                toolbar
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.md)
        }
        .statusBarHidden(true)
        .sheet(isPresented: $showParticipants) {
            participantSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
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
            HStack(spacing: 6) {
                Text(modeLabel)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(config.competitive ? Theme.Colour.forfeitRed : Theme.Colour.moneyGreen)
                Text("·").foregroundStyle(Theme.Colour.textSecondary)
                Text("\(stillLockedIn)/\(roster.count) still LockedIN")
                    .font(Theme.TypeScale.caption)
                    .foregroundStyle(Theme.Colour.textSecondary)
            }
        }
    }

    // MARK: - Compact group-status bar (tap to expand the participant panel)

    private var groupStatusBar: some View {
        Button { showParticipants = true } label: {
            HStack(spacing: Theme.Spacing.sm) {
                statusDot(Theme.Colour.moneyGreen, "\(focusedCount)", "focused")
                divider
                statusDot(Theme.Colour.accent, "\(breakCount)", "break")
                divider
                statusDot(Theme.Colour.forfeitRed, "\(distractedCount)", "distracted")
                Spacer()
                HStack(spacing: 4) {
                    Text("Details").font(.system(size: 11, weight: .bold, design: .rounded))
                    Image(systemName: "chevron.up").font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(Theme.Colour.textSecondary)
                .lineLimit(1)
                .fixedSize()
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colour.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func statusDot(_ colour: Color, _ value: String, _ label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(colour).frame(width: 8, height: 8)
            Text(value).font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.textPrimary).monospacedDigit()
            Text(label).font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
        }
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
    }

    private var divider: some View {
        Rectangle().fill(Theme.Colour.cardBorder).frame(width: 1, height: 14)
    }

    // MARK: - Room scene (isometric room + placed avatars)

    private var roomScene: some View {
        GeometryReader { geo in
            ZStack {
                IsometricRoomView(room: appStore.world.state.personalRoom)
                breakCorner(in: geo.size)
                ForEach(Array(roster.enumerated()), id: \.element.id) { i, p in
                    placedAvatar(p, at: placement(for: p, deskIndex: i), in: geo.size)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
        .overlay(alignment: .bottomLeading) { worldProgressBoard.padding(Theme.Spacing.sm) }
    }

    /// The desk a participant sits at — unless they're on break, then the break corner.
    private func placement(for p: SessionParticipant, deskIndex: Int) -> CGPoint {
        p.status == .onBreak ? breakSlot : slots[deskIndex % slots.count]
    }

    private func placedAvatar(_ p: SessionParticipant, at slot: CGPoint, in size: CGSize) -> some View {
        VStack(spacing: 2) {
            statusPill(p.status)
            SpriteAvatarView(character: p.character, status: p.status, size: 52, showStatusBadge: false)
        }
        .position(x: size.width * slot.x, y: size.height * slot.y)
        .animation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.8), value: slot)
    }

    /// A cosy break corner (mug on a side table) the avatar walks to on break.
    private func breakCorner(in size: CGSize) -> some View {
        let isUsed = breakCount > 0
        return VStack(spacing: 3) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(isUsed ? Theme.Colour.accent : Theme.Colour.textSecondary)
            RoundedRectangle(cornerRadius: 3)
                .fill(Theme.Colour.surfaceMid)
                .frame(width: 30, height: 8)
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.Colour.surface.opacity(isUsed ? 0.55 : 0.30)))
        .position(x: size.width * breakSlot.x, y: size.height * (breakSlot.y + 0.14))
    }

    // MARK: - In-room world-progress board ("what this room is building")

    private var worldProgressBoard: some View {
        let building = appStore.world.state.activeBuilding
        let type = building?.type ?? .libraryHub
        return HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: type.symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(type.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("BUILDING").font(.system(size: 8, weight: .heavy)).foregroundStyle(Theme.Colour.textSecondary)
                Text(type.title).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Theme.Colour.textPrimary)
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.Colour.surfaceMid).frame(width: 84, height: 5)
                    Capsule().fill(type.tint).frame(width: 84 * (building?.progress ?? 0), height: 5)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Theme.Colour.surface.opacity(0.94)))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
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

    // MARK: - Expandable participant panel (bottom sheet)

    private var participantSheet: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    Text("Participants").font(Theme.TypeScale.title2).foregroundStyle(Theme.Colour.textPrimary)
                    Spacer()
                    Text("\(focusedCount) focused · \(breakCount) break · \(distractedCount) distracted")
                        .font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                }
                ScrollView {
                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(roster) { p in participantCard(p) }
                    }
                }
                Text("Multiplayer is simulated for this demo — scripted study-mates.")
                    .font(Theme.TypeScale.caption)
                    .foregroundStyle(Theme.Colour.testBadgeFg)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(Theme.Spacing.lg)
        }
    }

    private func participantCard(_ p: SessionParticipant) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            SpriteAvatarView(character: p.character, status: p.status, size: 44, showStatusBadge: false, animated: false)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(p.isUser ? "You" : firstName(p.displayName))
                        .font(Theme.TypeScale.headline).foregroundStyle(Theme.Colour.textPrimary)
                    statusPill(p.status)
                }
                HStack(spacing: Theme.Spacing.lg) {
                    metric("\(focusedMinutes(p))m", "focused")
                    metric("\(p.distractions)", "off-task")
                    if config.competitive || p.isUser {
                        metric("\(warningsRemaining(p))", "warns left")
                    }
                }
            }
            Spacer()
            signalBars(for: p.status)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colour.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md)
            .strokeBorder(p.status == .distracted ? Theme.Colour.forfeitRed.opacity(0.5) : Theme.Colour.cardBorder, lineWidth: 1))
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value).font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.textPrimary).monospacedDigit()
            Text(label).font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
        }
        .lineLimit(1)
        .fixedSize()
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
