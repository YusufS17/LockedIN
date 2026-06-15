import SwiftUI

// MARK: - WorldView — your district (Phase 7, local-first)
//
// "The study room is where focus happens; the world is what focus creates." Shows the
// player's persisted economy (level + Focus XP + coins), a hero view of their personal
// room, and the district of buildings that grow from focus. Tap an unlocked building to
// direct your focus there; spend coins to break ground on a new plot. All state is the
// real persisted WorldStore — no mocks.

struct WorldView: View {

    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Coins to break ground on a new (unlocked, level-0) building.
    private let buildCost = 30

    @State private var showCustomizer = false
    @State private var showRoomBuilder = false
    @State private var burstBuildingID: String?   // tile to flourish after build/focus

    private var world: WorldStore { appStore.world }
    private var p: Progression { world.state.progression }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        levelCard
                        heroRoom
                        customizeButtons
                        districtSection
                        statsRow
                    }
                    .padding(Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
        }
        .statusBarHidden(true)
        .fullScreenCover(isPresented: $showCustomizer) {
            CharacterCustomizerView(initial: appStore.userCharacter, initialName: appStore.displayName) { appearance, name in
                appStore.userCharacter = appearance
                appStore.displayName = name
                CharacterPersistence.save(appearance: appearance, displayName: name)
            }
            .environment(appStore)
        }
        .fullScreenCover(isPresented: $showRoomBuilder) {
            PersonalRoomBuilderView().environment(appStore)
        }
    }

    private var customizeButtons: some View {
        HStack(spacing: Theme.Spacing.md) {
            customizeButton("Edit character", systemImage: "wand.and.stars") { showCustomizer = true }
            customizeButton("Customise room", systemImage: "house.fill") { showRoomBuilder = true }
        }
    }

    private func customizeButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(Theme.TypeScale.captionBold)
                .foregroundStyle(Theme.Colour.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
                .background(Theme.Colour.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.pill).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.Colour.textSecondary)
            }
            Spacer()
            Text("Your World").font(Theme.TypeScale.headline).foregroundStyle(Theme.Colour.textPrimary)
            Spacer()
            coinChip
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.sm)
    }

    private var coinChip: some View {
        HStack(spacing: 4) {
            Image(systemName: "circle.fill").font(.system(size: 10)).foregroundStyle(Theme.Colour.accent)
            Text("\(p.coins)").font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.textPrimary).monospacedDigit()
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 5)
        .background(Capsule().fill(Theme.Colour.surface))
        .overlay(Capsule().strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
    }

    // MARK: - Level

    private var levelCard: some View {
        card {
            HStack(spacing: Theme.Spacing.lg) {
                ZStack {
                    Circle().stroke(Theme.Colour.surfaceMid, lineWidth: 7).frame(width: 64, height: 64)
                    Circle().trim(from: 0, to: p.levelProgress)
                        .stroke(Theme.Colour.accent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90)).frame(width: 64, height: 64)
                    Text("\(p.level)").font(Theme.TypeScale.title2).foregroundStyle(Theme.Colour.textPrimary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(p.level)").font(Theme.TypeScale.headline).foregroundStyle(Theme.Colour.textPrimary)
                    Text("\(p.xpIntoLevel) / \(p.xpForThisLevel) Focus XP")
                        .font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary).monospacedDigit()
                    Text("\(p.focusXP) total XP earned")
                        .font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary).monospacedDigit()
                }
                Spacer()
            }
        }
    }

    // MARK: - Hero personal room

    private var heroRoom: some View {
        ZStack {
            IsometricRoomView(room: world.state.personalRoom)
            GeometryReader { geo in
                SpriteAvatarView(character: appStore.userStudyCharacter, status: .deepFocus, size: 64)
                    .position(x: geo.size.width * 0.50, y: geo.size.height * 0.56)
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
        .overlay(alignment: .bottomLeading) {
            Text("\(appStore.displayName.isEmpty ? "Your" : appStore.displayName + "’s") Room")
                .font(Theme.TypeScale.captionBold)
                .foregroundStyle(Theme.Colour.textPrimary)
                .padding(.horizontal, Theme.Spacing.sm).padding(.vertical, 5)
                .background(Capsule().fill(Theme.Colour.surface.opacity(0.92)))
                .padding(Theme.Spacing.sm)
        }
    }

    // MARK: - District

    private var districtSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("YOUR DISTRICT").font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.textSecondary)
                Spacer()
                Text("Tap to focus here").font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
            }
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(world.state.buildings) { b in
                    buildingTile(b)
                }
            }
        }
    }

    private func buildingTile(_ b: WorldBuilding) -> some View {
        let isActive = b.id == world.state.activeBuildingID
        let canBuild = b.unlocked && b.level == 0
        let popped = burstBuildingID == b.id
        return Button {
            if b.unlocked && b.level > 0 {
                world.setActiveBuilding(b.type)
                celebrate(b.id)
            } else if canBuild {
                if world.startBuilding(b.type, cost: buildCost) { celebrate(b.id) }
            }
        } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Image(systemName: b.unlocked ? b.type.symbol : "lock.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(b.unlocked ? b.type.tint : Theme.Colour.textSecondary)
                    Spacer()
                    if isActive {
                        Image(systemName: "scope").font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.Colour.accent)
                    }
                }
                Text(b.type.title)
                    .font(Theme.TypeScale.captionBold)
                    .foregroundStyle(b.unlocked ? Theme.Colour.textPrimary : Theme.Colour.textSecondary)
                    .lineLimit(1).minimumScaleFactor(0.7)

                if !b.unlocked {
                    Text("Locked").font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                } else if b.level == 0 {
                    Text("Build · \(buildCost) coins")
                        .font(Theme.TypeScale.caption)
                        .foregroundStyle(p.coins >= buildCost ? Theme.Colour.moneyGreen : Theme.Colour.forfeitRed)
                } else {
                    Text("Level \(b.level)").font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.Colour.surfaceMid).frame(height: 6)
                            Capsule().fill(b.type.tint).frame(width: geo.size.width * b.progress, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 104)
            .padding(Theme.Spacing.md)
            .background(Theme.Colour.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .strokeBorder(isActive ? Theme.Colour.accent : Theme.Colour.cardBorder,
                              lineWidth: isActive ? 2.5 : 1))
            .overlay(SparkleBurst(trigger: popped, count: 10, radius: 56, colour: b.type.tint))
            .scaleEffect(popped ? 1.06 : 1)
            .opacity(b.unlocked ? 1 : 0.6)
        }
        .buttonStyle(.plain)
    }

    /// Flourish a building tile after a successful build / focus tap.
    private func celebrate(_ id: String) {
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { burstBuildingID = id }
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation(.easeOut(duration: 0.2)) { burstBuildingID = nil }
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            stat("\(p.sessionsCompleted)", "Sessions")
            stat("\(p.currentStreak)", "Streak")
            stat("\(p.bestStreak)", "Best streak")
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(Theme.TypeScale.title2).foregroundStyle(Theme.Colour.textPrimary).monospacedDigit()
            Text(label).font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colour.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
    }

    // MARK: - Bits

    private func card<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colour.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
    }
}

#Preview("World") {
    WorldView().environment(AppStore())
}
