import SwiftUI

// MARK: - SettlementResultsView — the consequence reveal (Demo10)
//
// The payoff screen. Runs the REAL Int-pence settlement through the CommitmentService
// (SettlementEngine.run), then reveals it as a staged, animated sequence: a trophy
// pop, a coin count-up, the session summary, the Champion / Biggest Culprit crowning,
// the room's money landing (£ returned / £ forfeited — the project's core value), and
// a world-contribution teaser. Supportive mode hides the Culprit (no calling-out).
//
// All animation is gated on Reduce Motion. Money is Int pence, rendered via MoneyLabel.

struct SettlementResultsView: View {

    let config: RoomConfig
    let participants: [SessionParticipant]
    var onDone: () -> Void

    @Environment(AppStore.self) private var appStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var result: SessionResult?
    @State private var reveal = 0          // staged reveal index (0 = nothing yet)
    @State private var coinsShown = 0      // animated coin count-up
    @State private var worldFill: Double = 0

    // Derived session figures (deterministic).
    private var focusedMinutes: Int {
        participants.reduce(0) { $0 + Int((Double(config.focusMinutes) * Double($1.focusPct) / 100).rounded()) }
    }
    private var earnedCoins: Int { max(1, focusedMinutes / 8) }
    private var passedCount: Int { result?.results.filter { $0.verdict == .passed }.count ?? 0 }
    private var failedCount: Int { result?.results.filter { $0.verdict == .failed }.count ?? 0 }

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()
            if let result {
                loaded(result)
            } else {
                settlingView
            }
        }
        .statusBarHidden(true)
        .task { await settleAndReveal() }
    }

    // MARK: - Loading (settlement in flight)

    private var settlingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            BrandLockHeader()
            Spacer()
            ProgressView()
                .tint(Theme.Colour.accent)
                .scaleEffect(1.4)
            Text("Settling the stakes…")
                .font(Theme.TypeScale.headline)
                .foregroundStyle(Theme.Colour.textSecondary)
            Spacer()
        }
        .padding(Theme.Spacing.lg)
    }

    // MARK: - Loaded reveal

    private func loaded(_ result: SessionResult) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                BrandLockHeader()
                    .padding(.top, Theme.Spacing.md)

                trophy
                Text("Room complete")
                    .font(Theme.TypeScale.largeTitle)
                    .foregroundStyle(Theme.Colour.textPrimary)

                coinReward

                if reveal >= 2 { summaryCard.transition(revealTransition) }
                if reveal >= 3 { crowningCard(result).transition(revealTransition) }
                if config.isStaked, reveal >= 4 { settlementCard(result).transition(revealTransition) }
                if reveal >= 5 { worldCard.transition(revealTransition) }
                if reveal >= 6 { actions.transition(revealTransition) }
            }
            .padding(Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Trophy + coins

    private var trophy: some View {
        ZStack {
            Circle()
                .fill(Theme.Colour.accentSoft.opacity(0.35))
                .frame(width: 108, height: 108)
            Circle()
                .fill(Theme.Colour.accent)
                .frame(width: 84, height: 84)
                .shadow(color: Theme.Colour.accent.opacity(0.5), radius: 12, y: 4)
            Image(systemName: "trophy.fill")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(Theme.Colour.textOnAccent)
        }
        .scaleEffect(reveal >= 1 ? 1 : 0.3)
        .opacity(reveal >= 1 ? 1 : 0)
        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.55), value: reveal)
    }

    private var coinReward: some View {
        VStack(spacing: 2) {
            Text("Great focus, team! You earned")
                .font(Theme.TypeScale.body)
                .foregroundStyle(Theme.Colour.textSecondary)
            Text("+\(coinsShown) coins")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.Colour.accent)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .opacity(reveal >= 1 ? 1 : 0)
    }

    // MARK: - Session summary

    private var summaryCard: some View {
        card {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                cardTitle("SESSION SUMMARY")
                HStack(spacing: Theme.Spacing.sm) {
                    statTile("person.3.fill", "\(participants.count)", "Participants", Theme.Colour.textPrimary)
                    statTile("clock.fill", "\(focusedMinutes)", "Focused min", Theme.Colour.accent)
                    statTile("checkmark.seal.fill", "\(passedCount)", "Passed", Theme.Colour.moneyGreen)
                    statTile("xmark.seal.fill", "\(failedCount)", "Failed", Theme.Colour.forfeitRed)
                }
            }
        }
    }

    private func statTile(_ icon: String, _ value: String, _ label: String, _ tint: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(Theme.TypeScale.title2)
                .foregroundStyle(Theme.Colour.textPrimary)
                .monospacedDigit()
            Text(label)
                .font(Theme.TypeScale.caption)
                .foregroundStyle(Theme.Colour.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .padding(.horizontal, 2)
        .background(Theme.Colour.surfaceMid)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
    }

    // MARK: - Champion / Culprit

    private func crowningCard(_ result: SessionResult) -> some View {
        card {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                if let champ = result.champion {
                    crownColumn("🏆", "LockedIN Champion", champ,
                                detail: "\(focusedFor(champ)) min · \(champ.focusPct)%",
                                tint: Theme.Colour.accent)
                }
                if config.competitive, let culprit = result.culprit {
                    Divider().frame(height: 96)
                    crownColumn("💀", "Biggest Culprit", culprit,
                                detail: "\(culprit.distractions) distractions · \(culprit.focusPct)%",
                                tint: Theme.Colour.forfeitRed)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func crownColumn(_ emoji: String, _ title: String, _ p: SessionParticipant,
                             detail: String, tint: Color) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(emoji).font(.system(size: 26))
            SpriteAvatarView(character: p.character, status: p.status, size: 56, showStatusBadge: false)
            Text(title)
                .font(Theme.TypeScale.captionBold)
                .foregroundStyle(tint)
                .multilineTextAlignment(.center)
            Text(p.isUser ? "You" : firstName(p.displayName))
                .font(Theme.TypeScale.headline)
                .foregroundStyle(Theme.Colour.textPrimary)
            Text(detail)
                .font(Theme.TypeScale.caption)
                .foregroundStyle(Theme.Colour.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Money settlement (the core value)

    private func settlementCard(_ result: SessionResult) -> some View {
        card {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                cardTitle("STAKES SETTLED")
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Returned").font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                        MoneyLabel(result.totalReturnedPence)
                            .foregroundStyle(Theme.Colour.moneyGreen)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Forfeited").font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                        MoneyLabel(result.totalForfeitedPence)
                            .foregroundStyle(Theme.Colour.forfeitRed)
                    }
                }
                Divider()
                ForEach(result.results) { r in
                    HStack {
                        SpriteAvatarView(character: r.participant.character, status: .idle, size: 28)
                        Text(r.participant.isUser ? "You" : firstName(r.participant.displayName))
                            .font(Theme.TypeScale.body)
                            .foregroundStyle(Theme.Colour.textPrimary)
                        Spacer()
                        Text(r.verdict == .passed ? "returned" : "forfeited")
                            .font(Theme.TypeScale.caption)
                            .foregroundStyle(Theme.Colour.textSecondary)
                        MoneyLabel(r.verdict == .passed ? r.returnedPence : r.forfeitedPence, compact: true)
                            .foregroundStyle(r.verdict == .passed ? Theme.Colour.moneyGreen : Theme.Colour.forfeitRed)
                    }
                }
                Text("TEST MODE — NO REAL MONEY MOVED")
                    .font(Theme.TypeScale.caption)
                    .foregroundStyle(Theme.Colour.testBadgeFg)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, Theme.Spacing.xs)
            }
        }
    }

    // MARK: - World contribution (teaser — full layer is v2)

    private var worldCard: some View {
        card {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                cardTitle("WORLD CONTRIBUTION")
                HStack {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.Colour.accentTeal)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Library Hub").font(Theme.TypeScale.headline).foregroundStyle(Theme.Colour.textPrimary)
                        Text("\(Int(worldFill * 100))% complete")
                            .font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                    }
                    Spacer()
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.Colour.surfaceMid).frame(height: 10)
                        Capsule().fill(Theme.Colour.accent)
                            .frame(width: geo.size.width * worldFill, height: 10)
                    }
                }
                .frame(height: 10)
                Text("Your \(focusedMinutes) focused minutes build the world all members share.")
                    .font(Theme.TypeScale.caption)
                    .foregroundStyle(Theme.Colour.textSecondary)
            }
        }
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button { onDone() } label: {
                Text("Start another session")
                    .font(Theme.TypeScale.headline)
                    .foregroundStyle(Theme.Colour.buttonText)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colour.buttonFill)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
            }
            // Honest: the world layer ships next — labelled, not a dead button.
            Text("View world — coming soon")
                .font(Theme.TypeScale.caption)
                .foregroundStyle(Theme.Colour.textSecondary)
        }
    }

    // MARK: - Reveal driver

    private func settleAndReveal() async {
        let settled = await SettlementEngine.run(
            config: config, participants: participants, service: appStore.commitmentService
        )
        withAnimation { result = settled }

        let coinStep = max(1, earnedCoins / 18)

        // Stage 1: trophy + coin count-up.
        await step(0.25) { advance() }                       // reveal 1
        for c in stride(from: 0, through: earnedCoins, by: coinStep) {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.05)) { coinsShown = min(c, earnedCoins) }
            try? await Task.sleep(for: .seconds(0.03))
        }
        coinsShown = earnedCoins

        // Stages 2–6: cards cascade in.
        for _ in 2...6 { await step(0.28) { advance() } }

        // World bar fills last.
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.8)) { worldFill = 0.72 }
    }

    private func advance() {
        withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.8)) { reveal += 1 }
    }

    private func step(_ seconds: Double, _ body: () -> Void) async {
        body()
        try? await Task.sleep(for: .seconds(reduceMotion ? 0 : seconds))
    }

    private var revealTransition: AnyTransition {
        reduceMotion ? .opacity : .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        )
    }

    // MARK: - Bits

    private func focusedFor(_ p: SessionParticipant) -> Int {
        Int((Double(config.focusMinutes) * Double(p.focusPct) / 100).rounded())
    }

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

#Preview("Settlement reveal") {
    SettlementResultsView(
        config: .preset,
        participants: SessionParticipant.makeRoster(
            userCharacter: CharacterCatalog.first, userName: "You", config: .preset
        ),
        onDone: {}
    )
    .environment(AppStore())
}
