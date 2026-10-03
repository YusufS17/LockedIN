import SwiftUI

/// Shared native controls around the pixel world.
struct StudioButtonStyle: ButtonStyle {
    var primary = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(Theme.Colour.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(primary ? Theme.Colour.accent : Theme.Colour.surface,
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .strokeBorder(primary ? Theme.Colour.testBadgeFg.opacity(0.38) : Theme.Colour.cardBorder, lineWidth: 1))
            .background(RoundedRectangle(cornerRadius: 14)
                .fill(primary ? Theme.Colour.testBadgeFg.opacity(0.55) : Theme.Colour.cardBorder.opacity(0.65))
                .offset(y: configuration.isPressed ? 0 : 3))
            .offset(y: configuration.isPressed ? 2 : 0)
            .opacity(isEnabled ? 1 : 0.45)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct StudioHeader: View {
    let title: String
    var subtitle: String? = nil
    var close: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: close) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(Theme.Colour.surface, in: Circle())
                    .overlay(Circle().strokeBorder(Theme.Colour.cardBorder.opacity(0.7)))
            }
            .accessibilityLabel("Back")
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(.headline, design: .rounded, weight: .bold))
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(Theme.Colour.textSecondary)
                }
            }
            Spacer()
        }
        .foregroundStyle(Theme.Colour.textPrimary)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}

/// One consistent projection for personal-room previews and their occupant.
struct PersonalRoomScene: View {
    let room: PersonalRoom
    let character: StudyCharacter

    var body: some View {
        ZStack {
            IsometricRoomView(room: room)
            GeometryReader { geo in
                let cell = RoomLayout.scale(in: geo.size)
                let feet = RoomLayout.project(RoomLayout.heroStand, in: geo.size)
                let height = 48 * cell
                SpriteAvatarView(character: character, status: .idle, size: height)
                    .position(x: feet.x, y: feet.y - height / 2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your furnished study room and custom avatar")
    }
}

struct StudioEyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(.caption2, design: .monospaced, weight: .bold))
            .tracking(1.5)
            .foregroundStyle(Theme.Colour.textSecondary)
    }
}

struct StudioCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(Theme.Colour.surface, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Theme.Colour.cardBorder.opacity(0.8), lineWidth: 1))
    }
}

/// A consistent selection treatment for actual wardrobe and room inventory.
struct StudioSelectionTile: ViewModifier {
    let selected: Bool

    func body(content: Content) -> some View {
        content
            .background(selected ? Theme.Colour.accentSoft.opacity(0.22) : Theme.Colour.surface,
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .strokeBorder(selected ? Theme.Colour.testBadgeFg : Theme.Colour.cardBorder.opacity(0.7),
                              lineWidth: selected ? 2 : 1))
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct StudioSectionHeading: View {
    let title: String
    var detail: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(.headline, design: .rounded, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            if let detail {
                Text(detail).font(.caption).foregroundStyle(Theme.Colour.textSecondary)
            }
        }
    }
}

struct StudioCoinBalance: View {
    let coins: Int

    var body: some View {
        HStack(spacing: 6) {
            PixelIconView(icon: .coin, size: 16)
            Text("\(coins)").font(.system(.caption, design: .rounded, weight: .bold)).monospacedDigit()
        }
        .padding(.horizontal, 11).padding(.vertical, 8)
        .background(Theme.Colour.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.Colour.cardBorder.opacity(0.8)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(coins) earned coins")
    }
}
