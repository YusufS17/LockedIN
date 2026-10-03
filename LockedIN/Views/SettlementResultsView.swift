import SwiftUI

// Recorded user timer/break results, idempotent progression and an optional room upgrade.
// Companion behaviour and the optional legacy stake flow remain explicitly simulated.

struct SettlementResultsView: View {

    let config: RoomConfig
    let participants: [SessionParticipant]
    var onDone: () -> Void

    @Environment(AppStore.self) private var appStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var result: SessionResult?
    @State private var reward: RewardOutcome?   // real XP/coins awarded + persisted
    @State private var reveal = 0          // staged reveal index (0 = nothing yet)
    @State private var coinsShown = 0      // animated coin count-up
    @State private var worldFill: Double = 0
    @State private var showWorld = false
    @State private var placedItemID: String?

    private var user: SessionParticipant? { participants.first(where: \.isUser) }
    private var focusTime: String {
        let seconds = user?.focusedSeconds ?? 0
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
    private var goalAnswer: String? {
        guard appStore.studySession.current?.user?.id == user?.id else { return nil }
        return appStore.studySession.current?.goalReview?.label
    }
    private var suggestedItem: RoomItem? {
        RoomItemCatalog.all.first {
            $0.cost > 0 && $0.cost <= appStore.world.state.progression.coins &&
            !appStore.world.ownsRoomItem($0.id) && [.plant, .rug, .chair, .poster].contains($0.slot)
        }
    }

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()
            if let result {
                loaded(result)
            } else {
                settlingView
            }
        }
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
            Text(config.isStaked ? "Settling test stakes…" : "Wrapping up your session…")
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
                VStack(spacing: 12) {
                    StudioEyebrow(text: "A little time, well spent")
                    trophy
                    Text(user?.leftEarly == true ? "See you next time" : "Room complete")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold)).tracking(-0.7)
                        .foregroundStyle(Theme.Colour.textPrimary)
                    Text(user?.leftEarly == true ? "Your room will be here when you’re ready." : "One more small step towards your world.")
                        .font(.subheadline).foregroundStyle(Theme.Colour.textSecondary)
                        .multilineTextAlignment(.center)
                    coinReward
                }.padding(.vertical, 16)

                if reveal >= 2 { summaryCard.transition(revealTransition) }
                if config.competitive, reveal >= 3 { crowningCard(result).transition(revealTransition) }
                if config.isStaked, reveal >= 4 { settlementCard(result).transition(revealTransition) }
                if reveal >= 5 {
                    if (reward?.coins ?? 0) > 0 { roomUpgrade.transition(revealTransition) }
                    worldCard.transition(revealTransition)
                }
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
            if user?.leftEarly == true {
                PixelIconView(icon: .mug, size: 62, tint: Theme.Colour.testBadgeFg)
                    .frame(width: 108, height: 108)
                    .background(Theme.Colour.surfaceMid, in: RoundedRectangle(cornerRadius: 24))
            } else {
                SessionMedal().frame(width: 108, height: 120)
                SparkleBurst(trigger: reveal >= 1, count: 8, radius: 64)
            }
        }
        .accessibilityHidden(true)
        .scaleEffect(reveal >= 1 ? 1 : 0.7)
        .opacity(reveal >= 1 ? 1 : 0)
        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.75), value: reveal)
    }

    private var coinReward: some View {
        VStack(spacing: 2) {
            Text(config.quickDemo ? "Demo session · no coins saved" : ((reward?.coins ?? 0) > 0 ? "Saved to your room fund" : "Complete the planned time to earn coins"))
                .font(Theme.TypeScale.body)
                .foregroundStyle(Theme.Colour.textSecondary)
            Text("+\(coinsShown) coins").accessibilityIdentifier("study.coins")
                .font(.system(.title, design: .rounded, weight: .heavy))
                .foregroundStyle(Theme.Colour.testBadgeFg)
                .monospacedDigit()
                .contentTransition(.numericText())
            if let reward, reward.leveledUp, reveal >= 2 {
                Label("Level \(reward.newLevel) reached!", systemImage: "star.fill")
                    .font(Theme.TypeScale.captionBold)
                    .foregroundStyle(Theme.Colour.moneyGreen)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .opacity(reveal >= 1 ? 1 : 0)
    }

    // MARK: - Session summary

    private var summaryCard: some View {
        card {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack(spacing: 12) {
                    AvatarPortraitView(appearance: appStore.userCharacter, size: 44)
                    VStack(alignment: .leading, spacing: 4) {
                        cardTitle("YOUR SESSION")
                        Text(config.subject).font(.system(.headline, design: .rounded))
                        Text(config.goal).font(.caption).foregroundStyle(Theme.Colour.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
                Rectangle().fill(Theme.Colour.cardBorder.opacity(0.6)).frame(height: 1)
                (dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: Theme.Spacing.sm)) : AnyLayout(HStackLayout(spacing: Theme.Spacing.sm))) {
                    statTile("clock.fill", focusTime, "Your timer", Theme.Colour.accent)
                    statTile("cup.and.saucer", "\(user?.recordedBreakCount ?? 0)", "Breaks", Theme.Colour.textPrimary)
                    statTile("hand.raised", "\(user?.distractions ?? 0)", "Reported", Theme.Colour.textSecondary)
                }
                Text("\(user?.focusPct ?? 0)% of planned timer time · \(user?.recordedBreakSeconds ?? 0)s on break")
                    .font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                if let goalAnswer {
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: "lock").font(.caption)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Your private check-in").font(.caption.weight(.semibold))
                            Text(goalAnswer).font(.subheadline)
                        }
                    }.foregroundStyle(Theme.Colour.textSecondary)
                }
                DisclosureGroup("About these numbers") {
                    Text("Timer time is not a measure of attention. Breaks and interruptions are self-reported; other app use is not tracked.")
                        .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
                        .padding(.top, 6)
                }.font(.caption).tint(Theme.Colour.textSecondary)
                if participants.count > 1 {
                    Text("Demo companions are simulated and do not add to your earned progress.")
                        .font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
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
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .padding(.horizontal, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value)")
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
                cardTitle(result.results.contains(where: \.settlementFailed) ? "TEST SETTLEMENT INCOMPLETE" : "TEST STAKES SETTLED")
                if result.results.contains(where: \.settlementFailed) {
                    Text("Some test settlements failed. Only confirmed amounts appear below; no real money moved.")
                        .font(Theme.TypeScale.caption)
                }
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
                        SpriteAvatarView(character: r.participant.character, status: .idle, size: 28, animated: false)
                        Text(r.participant.isUser ? "You" : firstName(r.participant.displayName))
                            .font(Theme.TypeScale.body)
                            .foregroundStyle(Theme.Colour.textPrimary)
                        Spacer()
                        Text(r.settlementFailed ? "not settled" : (r.verdict == .passed ? "returned" : "forfeited"))
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

    // MARK: - World contribution (real — banks Focus XP into the active building)

    private var worldCard: some View {
        let building = appStore.world.state.activeBuilding
        let type = building?.type ?? .libraryHub
        return card {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                cardTitle("WORLD CONTRIBUTION")
                (dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))) {
                    Image(systemName: type.symbol)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(type.tint)
                        .frame(width: 56, height: 62)
                        .background(Theme.Colour.surfaceMid.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colour.cardBorder.opacity(0.7)))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(type.title).font(Theme.TypeScale.headline).foregroundStyle(Theme.Colour.textPrimary)
                        Text("Level \(building?.level ?? 1) · \(Int(worldFill * 100))% to next")
                            .font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                    }
                    Spacer()
                    if let reward {
                        Text("+\(reward.focusXP) XP")
                            .font(Theme.TypeScale.captionBold)
                            .foregroundStyle(Theme.Colour.testBadgeFg)
                    }
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.Colour.surfaceMid).frame(height: 10)
                        Capsule().fill(type.tint)
                            .frame(width: geo.size.width * worldFill, height: 10)
                    }
                }
                .frame(height: 10)
                Text("Your session grows your saved personal world.")
                    .font(Theme.TypeScale.caption)
                    .foregroundStyle(Theme.Colour.textSecondary)
            }
        }
    }

    private var roomUpgrade: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                cardTitle("MAKE IT YOURS")
                if let placedItemID, let item = RoomItemCatalog.item(id: placedItemID) {
                    Text("\(item.name) is in your room.").accessibilityIdentifier("room.purchaseConfirmation").font(Theme.TypeScale.headline)
                    PersonalRoomScene(room: appStore.world.state.personalRoom, character: appStore.userStudyCharacter)
                        .aspectRatio(RoomLayout.imageSize.width / RoomLayout.imageSize.height, contentMode: .fit)
                } else if let item = suggestedItem {
                    (dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16)) : AnyLayout(HStackLayout(spacing: 16))) {
                        if let image = RoomComposer.itemImage(item) {
                            Image(uiImage: image).interpolation(.none).resizable().scaledToFit()
                                .frame(width: 64, height: 72)
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            Text("\(item.name) \(item.slot.title.lowercased())").font(Theme.TypeScale.headline)
                            Text("You have \(appStore.world.state.progression.coins) coins saved.")
                                .font(Theme.TypeScale.caption)
                        }
                    }
                    Button("Add to my room · \(item.cost) coins") {
                        switch appStore.world.selectRoomItem(item.id) {
                        case .placed, .purchasedAndPlaced: placedItemID = item.id
                        case .cannotAfford: break
                        }
                    }.buttonStyle(StudioButtonStyle(primary: true))
                    .accessibilityIdentifier("room.buySuggested")
                } else {
                    Text("Your coins are saved. Find your next upgrade in Decorate.")
                        .font(Theme.TypeScale.body)
                }
            }
        }
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 10) {
            Button { onDone() } label: {
                HStack {
                    PixelIconView(icon: .house, size: 20, tint: Theme.Colour.textPrimary)
                    Text("Return to your room")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
            }.buttonStyle(StudioButtonStyle(primary: true))
            .accessibilityIdentifier("study.done")
            Button { showWorld = true } label: {
                Label("View world", systemImage: "map")
            }.buttonStyle(StudioButtonStyle())
        }
        .fullScreenCover(isPresented: $showWorld) { WorldView().environment(appStore) }
    }

    // MARK: - Reveal driver

    private func settleAndReveal() async {
        let settled = await SettlementEngine.run(
            config: config, participants: participants, service: appStore.commitmentService
        )
        withAnimation(reduceMotion ? nil : .default) { result = settled }

        // Award real, persisted Focus XP + coins for the user's session (once).
        if reward == nil, let me = participants.first(where: { $0.isUser }) {
            reward = appStore.world.applySession(user: me, config: config)
        }
        let coinTarget = config.quickDemo ? 0 : (reward?.coins ?? 0)
        let coinStep = max(1, coinTarget / 18)
        if reduceMotion {
            coinsShown = coinTarget
            worldFill = appStore.world.state.activeBuilding?.progress ?? 0
            reveal = 6
            return
        }

        // Stage 1: trophy + coin count-up.
        await step(0.25) { advance() }                       // reveal 1
        for c in stride(from: 0, through: coinTarget, by: coinStep) {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.05)) { coinsShown = min(c, coinTarget) }
            try? await Task.sleep(for: .seconds(0.03))
        }
        coinsShown = coinTarget

        // Stages 2–6: cards cascade in.
        for _ in 2...6 { await step(0.28) { advance() } }

        // World bar fills to the active building's real progress.
        let target = appStore.world.state.activeBuilding?.progress ?? 0
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.8)) { worldFill = target }
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
        (p.focusedSeconds ?? 0) / 60
    }

    private func cardTitle(_ text: String) -> some View {
        StudioEyebrow(text: text)
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

private struct SessionMedal: View {
    var body: some View {
        GeometryReader { geometry in
            let side = geometry.size.width
            ZStack(alignment: .top) {
                HStack(spacing: side * 0.12) {
                    ribbon.rotationEffect(.degrees(12))
                    ribbon.rotationEffect(.degrees(-12))
                }
                .frame(width: side * 0.58, height: side * 0.50)
                .offset(y: side * 0.62)
                medalShape.fill(Theme.Colour.testBadgeFg)
                    .frame(width: side, height: side)
                medalShape.fill(Theme.Colour.accent)
                    .frame(width: side - 8, height: side - 8).padding(4)
                medalShape.stroke(Theme.Colour.surface.opacity(0.85), lineWidth: 2)
                    .frame(width: side - 20, height: side - 20).padding(10)
                Image(systemName: "star.fill")
                    .font(.system(size: side * 0.39, weight: .bold))
                    .foregroundStyle(Theme.Colour.surface)
                    .shadow(color: Theme.Colour.testBadgeFg, radius: 0, y: 3)
                    .frame(width: side, height: side)
            }
        }
    }

    private var ribbon: some View {
        Rectangle().fill(Theme.Colour.accent)
            .overlay(Rectangle().strokeBorder(Theme.Colour.testBadgeFg, lineWidth: 2))
    }

    private var medalShape: MedalOutline { MedalOutline() }
}

private struct MedalOutline: Shape {
    func path(in rect: CGRect) -> Path {
        let points: [CGPoint] = [
            .init(x: 0.30, y: 0), .init(x: 0.70, y: 0),
            .init(x: 0.70, y: 0.08), .init(x: 0.85, y: 0.08),
            .init(x: 0.85, y: 0.18), .init(x: 0.94, y: 0.18),
            .init(x: 0.94, y: 0.30), .init(x: 1, y: 0.30),
            .init(x: 1, y: 0.70), .init(x: 0.94, y: 0.70),
            .init(x: 0.94, y: 0.82), .init(x: 0.85, y: 0.82),
            .init(x: 0.85, y: 0.92), .init(x: 0.70, y: 0.92),
            .init(x: 0.70, y: 1), .init(x: 0.30, y: 1),
            .init(x: 0.30, y: 0.92), .init(x: 0.15, y: 0.92),
            .init(x: 0.15, y: 0.82), .init(x: 0.06, y: 0.82),
            .init(x: 0.06, y: 0.70), .init(x: 0, y: 0.70),
            .init(x: 0, y: 0.30), .init(x: 0.06, y: 0.30),
            .init(x: 0.06, y: 0.18), .init(x: 0.15, y: 0.18),
            .init(x: 0.15, y: 0.08), .init(x: 0.30, y: 0.08)
        ]
        return Path { path in
            path.addLines(points.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) })
            path.closeSubpath()
        }
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
