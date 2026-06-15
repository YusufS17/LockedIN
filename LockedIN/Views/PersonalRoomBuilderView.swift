import SwiftUI

// MARK: - PersonalRoomBuilderView — customise your study room (world-layer §14)
//
// A fixed-slot room builder, mirroring the character customizer's feel: a live isometric
// preview at the top, a slot selector (Floor, Wall, Rug, Desk, …), and a row of item
// options for the selected slot. Free items apply instantly; premium ones show a coin
// price and buy-on-tap if affordable (cosmetic-only, never pay-to-win). All edits write
// straight through WorldStore (RoomCustomisationService) and persist immediately, so the
// room shows everywhere — hero room, live session, solo room.

struct PersonalRoomBuilderView: View {

    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss

    @State private var slot: RoomSlot = .floor
    @State private var toast: String?

    private var world: WorldStore { appStore.world }
    private var room: PersonalRoom { world.state.personalRoom }
    private var coins: Int { world.state.progression.coins }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Colour.background.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        preview
                        slotSelector
                        itemRow
                    }
                    .padding(Theme.Spacing.lg)
                    .padding(.bottom, 90)
                }
            }
            doneBar
            if let toast { toastView(toast) }
        }
        .statusBarHidden(true)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.Colour.textSecondary)
            }
            Spacer()
            Text("Your Room").font(Theme.TypeScale.headline).foregroundStyle(Theme.Colour.textPrimary)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "circle.fill").font(.system(size: 10)).foregroundStyle(Theme.Colour.accent)
                Text("\(coins)").font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.textPrimary).monospacedDigit()
            }
            .padding(.horizontal, Theme.Spacing.sm).padding(.vertical, 5)
            .background(Capsule().fill(Theme.Colour.surface))
            .overlay(Capsule().strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
        }
        .padding(.horizontal, Theme.Spacing.lg).padding(.top, Theme.Spacing.lg).padding(.bottom, Theme.Spacing.sm)
    }

    // MARK: - Live preview

    private var preview: some View {
        ZStack {
            IsometricRoomView(room: room)
            GeometryReader { geo in
                SpriteAvatarView(character: appStore.userStudyCharacter, status: .deepFocus, size: 60)
                    .position(x: geo.size.width * 0.50, y: geo.size.height * 0.56)
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
        .animation(.easeInOut(duration: 0.2), value: room)
    }

    // MARK: - Slot selector

    private var slotSelector: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("WHAT TO CHANGE").font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(RoomSlot.allCases) { s in
                        slotChip(s)
                    }
                }
                .padding(.vertical, 4).padding(.horizontal, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func slotChip(_ s: RoomSlot) -> some View {
        let selected = s == slot
        return Button { withAnimation(.easeInOut(duration: 0.15)) { slot = s } } label: {
            VStack(spacing: 4) {
                Image(systemName: s.symbol).font(.system(size: 16, weight: .semibold))
                Text(s.title).font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(selected ? Theme.Colour.buttonText : Theme.Colour.textSecondary)
            .frame(width: 64, height: 56)
            .background(selected ? Theme.Colour.buttonFill : Theme.Colour.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md)
                .strokeBorder(selected ? Theme.Colour.accent : Theme.Colour.cardBorder, lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Item options for the selected slot

    private var itemRow: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(slot.title.uppercased()).font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.textSecondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 12)], spacing: 12) {
                ForEach(RoomItemCatalog.items(for: slot)) { item in
                    itemTile(item)
                }
            }
        }
    }

    private func itemTile(_ item: RoomItem) -> some View {
        let selected = room.itemID(for: slot) == item.id
        let owned = world.ownsRoomItem(item.id)
        return Button { choose(item) } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    swatch(item)
                    if !owned { priceTag(item.cost) }
                }
                Text(item.name)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.Colour.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colour.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md)
                .strokeBorder(selected ? Theme.Colour.accent : Theme.Colour.cardBorder, lineWidth: selected ? 2.5 : 1))
            .opacity(owned ? 1 : 0.85)
        }
        .buttonStyle(.plain)
    }

    /// A small representative swatch: the item tint with the slot symbol on top.
    /// "None" items (clear tint) render as a subtle dashed empty slot.
    private func swatch(_ item: RoomItem) -> some View {
        let isNone = item.name == "None"
        return ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                .fill(isNone ? Theme.Colour.surfaceMid : item.tint.opacity(0.9))
                .frame(width: 52, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm)
                        .strokeBorder(Theme.Colour.cardBorder, style: StrokeStyle(lineWidth: 1, dash: isNone ? [3] : []))
                )
            Image(systemName: isNone ? "nosign" : slot.symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isNone ? Theme.Colour.textSecondary : readableInk(on: item.tint))
        }
    }

    /// Pick legible ink for a glyph over a tinted swatch.
    private func readableInk(on tint: Color) -> Color {
        Theme.Colour.surface
    }

    private func priceTag(_ cost: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "circle.fill").font(.system(size: 6)).foregroundStyle(Theme.Colour.textOnAccent)
            Text("\(cost)").font(.system(size: 9, weight: .heavy)).foregroundStyle(Theme.Colour.textOnAccent)
        }
        .padding(.horizontal, 4).padding(.vertical, 2)
        .background(Capsule().fill(Theme.Colour.accent))
        .offset(x: 6, y: -6)
    }

    // MARK: - Done bar

    private var doneBar: some View {
        Button { dismiss() } label: {
            Text("Done")
                .font(Theme.TypeScale.headline).foregroundStyle(Theme.Colour.buttonText)
                .frame(maxWidth: .infinity).padding(Theme.Spacing.md)
                .background(Theme.Colour.buttonFill)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
        }
        .padding(.horizontal, Theme.Spacing.lg).padding(.bottom, Theme.Spacing.lg)
    }

    private func toastView(_ text: String) -> some View {
        Text(text)
            .font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.buttonText)
            .padding(.horizontal, Theme.Spacing.md).padding(.vertical, Theme.Spacing.sm)
            .background(Capsule().fill(Theme.Colour.buttonFill))
            .padding(.bottom, 80)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions

    /// Place an item — buying it first if premium and affordable; persists through WorldStore.
    private func choose(_ item: RoomItem) {
        switch world.selectRoomItem(item.id) {
        case .placed:
            withAnimation(.easeInOut(duration: 0.15)) {}
        case .purchasedAndPlaced:
            withAnimation(.easeInOut(duration: 0.15)) {}
            flash("Unlocked! ✨")
        case .cannotAfford:
            flash("Need \(item.cost) coins")
        }
    }

    private func flash(_ message: String) {
        withAnimation { toast = message }
        Task {
            try? await Task.sleep(for: .seconds(1.4))
            withAnimation { toast = nil }
        }
    }
}

#Preview("Room builder") {
    PersonalRoomBuilderView().environment(AppStore())
}
