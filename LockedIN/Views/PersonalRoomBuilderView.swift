import SwiftUI

struct PersonalRoomBuilderView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var slot: RoomSlot = .desk
    @State private var message: String?
    private var world: WorldStore { appStore.world }
    private var room: PersonalRoom { world.state.personalRoom }

    var body: some View {
        VStack(spacing: 0) {
            StudioHeader(title: "Your room studio", subtitle: "Small upgrades. A place that's yours.", close: { dismiss() })
            if !dynamicTypeSize.isAccessibilitySize {
                roomPreview.padding(.horizontal, 24).padding(.bottom, 16)
            }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    if dynamicTypeSize.isAccessibilitySize { roomPreview }
                    StudioSectionHeading(title: "Make room for you", detail: "Choose a piece. See it in your space.")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(RoomSlot.allCases) { category in
                                Button { slot = category; message = nil } label: {
                                    Label(category.title, systemImage: category.symbol)
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 14).frame(minHeight: 44)
                                        .modifier(StudioSelectionTile(selected: slot == category))
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(slot == category ? .isSelected : [])
                                .accessibilityIdentifier("room.category.\(category.rawValue)")
                            }
                        }
                    }
                    HStack {
                        StudioEyebrow(text: slot.title)
                        Spacer()
                        Text("\(RoomItemCatalog.items(for: slot).count) pieces")
                            .font(.caption2).foregroundStyle(Theme.Colour.textSecondary)
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 140 : 96), spacing: 12)], spacing: 12) {
                        ForEach(RoomItemCatalog.items(for: slot)) { item in itemTile(item) }
                    }
                    Text(message ?? "Owned pieces are ready to place. Priced pieces unlock and place with one tap.")
                        .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
                        .frame(maxWidth: .infinity).multilineTextAlignment(.center)
                        .accessibilityIdentifier("decorationMessage")
                }.padding(.horizontal, 24).padding(.bottom, 24)
            }
        }
        .foregroundStyle(Theme.Colour.textPrimary)
        .background(Theme.Colour.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 10) {
                if let message {
                    Text(message).font(.caption).foregroundStyle(Theme.Colour.textSecondary)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("decorationFeedback")
                }
                Button("Back to my room") { dismiss() }
                    .buttonStyle(StudioButtonStyle(primary: true))
                    .accessibilityIdentifier("room.done")
            }
            .padding(.horizontal, 24).padding(.vertical, 12)
            .background(Theme.Colour.background)
        }
    }

    private var roomPreview: some View {
        VStack(spacing: 0) {
            HStack {
                StudioEyebrow(text: "Your personal room")
                Spacer()
                StudioCoinBalance(coins: world.state.progression.coins)
            }.padding(.horizontal, 16).padding(.top, 12)
            PersonalRoomScene(room: room, character: appStore.userStudyCharacter)
                .frame(height: 210)
                .padding(.horizontal, 8)
            HStack(spacing: 7) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.Colour.focusGreen)
                Text("Your room saves as you decorate.")
                Spacer()
            }
            .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
            .padding(14).background(Theme.Colour.surface)
        }
        .background(Theme.Colour.surfaceMid.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.Colour.cardBorder))
    }

    private func itemTile(_ item: RoomItem) -> some View {
        let selected = room.itemID(for: slot) == item.id
        let owned = world.ownsRoomItem(item.id)
        return Button {
            switch world.selectRoomItem(item.id) {
            case .placed: message = "\(item.name) placed. Saved to your room."
            case .purchasedAndPlaced: message = "\(item.name) unlocked and placed."
            case .cannotAfford: message = "\(item.name) needs \(item.cost) coins. You have \(world.state.progression.coins)."
            }
        } label: {
            VStack(spacing: 8) {
                RoomItemThumbnail(item: item).frame(height: 84).padding(.horizontal, 8)
                Text(item.name).font(.caption.weight(.semibold)).multilineTextAlignment(.center)
                HStack(spacing: 3) {
                    if selected { Image(systemName: "checkmark") }
                    else if !owned { Image(systemName: "lock") }
                    Text(selected ? "Placed" : (owned ? "Owned" : "\(item.cost) coins"))
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(selected ? Theme.Colour.focusGreen : Theme.Colour.textSecondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .modifier(StudioSelectionTile(selected: selected))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.name), \(selected ? "placed" : owned ? "owned" : "\(item.cost) coins")")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("room.item.\(item.id)")
        .accessibilityHint(owned ? "Place in your room" : "Buy with earned coins and place in your room")
    }
}

/// Preview the same authored sprite used in the actual room.
private struct RoomItemThumbnail: View {
    let item: RoomItem
    var body: some View {
        if item.id.hasSuffix(".none") {
            Image(systemName: "minus.circle").font(.system(size: 28)).foregroundStyle(Theme.Colour.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let image = RoomComposer.itemImage(item) {
            Image(uiImage: image).interpolation(.none).resizable().scaledToFit()
                .padding(4).frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if item.slot == .floor || item.slot == .wall {
            Image(uiImage: RoomSpriteShell.image(floorTint: item.slot == .floor ? item.tint : nil,
                                                wallTint: item.slot == .wall ? item.tint : nil, phase: .day))
                .interpolation(.none).resizable().scaledToFit()
                .padding(4).frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            RoundedRectangle(cornerRadius: 12).fill(item.tint)
                .overlay(Image(systemName: item.slot.symbol).foregroundStyle(Theme.Colour.textPrimary.opacity(0.65)))
                .padding(10)
        }
    }
}

#Preview { PersonalRoomBuilderView().environment(AppStore()) }
