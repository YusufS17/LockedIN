import SwiftUI

// MARK: - LiveRoomScene — the multi-desk squad study room
//
// The shared study room as a real, occupied space: every participant sits at their OWN
// desk in the isometric room, doing their status animation, while one player on a break
// stands in the break corner. Composes the same art vocabulary as the single-occupant
// `IsometricRoomView` (RoomShell + RoomDecor + RoomAmbientLayer) so the rooms feel alike.
//
// The key trick is per-seat z-ordering: chair → avatar → desk-front, drawn back-row first,
// so each avatar appears to sit *behind* their desk and front desks overlap back ones.

struct LiveRoomScene: View {
    let participants: [SessionParticipant]
    let room: PersonalRoom
    /// Index (into `participants`) of the user when on a break — drawn in the break corner.
    var breakingUserIndex: Int?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Where a player stands when on a break.
    private let breakSlot = CGPoint(x: 0.85, y: 0.30)

    var body: some View {
        GeometryReader { geo in
            let s = geo.size
            let seats = RoomSeating.seats(participants.count)

            ZStack {
                RoomShell(size: s, room: room)

                // Back-wall decor.
                RoomDecor.window(size: s, room: room)
                RoomDecor.poster(size: s, room: room)
                RoomDecor.shelf(size: s, room: room)

                // Shared floor centre-piece + a cosy corner.
                RoomDecor.rug(size: s, room: room)
                RoomDecor.plant(size: s, room: room, at: CGPoint(x: 0.88, y: 0.52))
                RoomDecor.lamp(size: s, room: room, at: CGPoint(x: 0.12, y: 0.50))

                // Seated participants, back-to-front for correct overlap.
                ForEach(orderedSeating(seats), id: \.0) { i, seat in
                    if i == breakingUserIndex {
                        breakAvatar(participants[i], in: s)
                    } else {
                        seatUnit(participant: participants[i], seat: seat, size: s)
                    }
                }

                RoomAmbientLayer(size: s, room: room, reduceMotion: reduceMotion,
                                 lampAt: CGPoint(x: 0.12, y: 0.46))
            }
        }
    }

    /// Pair each participant with a seat, ordered back (small y) to front for draw order.
    private func orderedSeating(_ seats: [RoomSeat]) -> [(Int, RoomSeat)] {
        participants.indices
            .map { ($0, seats[$0 % seats.count]) }
            .sorted { $0.1.avatar.y < $1.1.avatar.y }
    }

    // MARK: - One seat: chair → avatar → desk-front

    private func seatUnit(participant p: SessionParticipant, seat: RoomSeat, size: CGSize) -> some View {
        let w = size.width, h = size.height
        let avatarSize = min(w, h) * 0.20 * seat.scale
        return ZStack {
            // Shadow + chair behind the avatar.
            RoomDecor.floorShadow(size: size, cx: seat.avatar.x, cy: seat.avatar.y + 0.05,
                                  rw: 0.14 * seat.scale, rh: 0.028)
            RoomDecor.chair(size: size, room: room, at: seat.avatar, scale: seat.scale * 0.85)

            // The seated avatar.
            SpriteAvatarView(character: p.character, status: p.status, size: avatarSize)
                .position(x: w * seat.avatar.x, y: h * seat.avatar.y)

            // The desk, drawn last so its front overlaps the avatar's lower body (seated look).
            RoomDecor.desk(size: size, room: room, at: seat.desk, scale: seat.scale * 0.74)

            // Floating status pill above the head.
            statusPill(p.status)
                .position(x: w * seat.avatar.x, y: h * (seat.avatar.y - 0.115 * seat.scale))
        }
    }

    private func breakAvatar(_ p: SessionParticipant, in size: CGSize) -> some View {
        let w = size.width, h = size.height
        return ZStack {
            RoomDecor.floorShadow(size: size, cx: breakSlot.x, cy: breakSlot.y + 0.13, rw: 0.10, rh: 0.022)
            SpriteAvatarView(character: p.character, status: .onBreak, size: min(w, h) * 0.18)
                .position(x: w * breakSlot.x, y: h * breakSlot.y)
            statusPill(.onBreak)
                .position(x: w * breakSlot.x, y: h * (breakSlot.y - 0.10))
        }
    }

    private func statusPill(_ status: AvatarStatus) -> some View {
        Text(status.label)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(status.ringColour))
            .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
            .fixedSize()
    }
}

// MARK: - RoomSeat / RoomSeating — fixed isometric desk layouts

struct RoomSeat {
    let avatar: CGPoint   // where the avatar sits (fractions)
    let desk: CGPoint     // desk centre (a touch lower/front of the avatar)
    let scale: CGFloat
}

enum RoomSeating {
    /// Fixed isometric seat layouts for 1…8 occupants. Avatars sit behind their desks;
    /// the desk centre sits slightly lower so its front face overlaps the body.
    static func seats(_ count: Int) -> [RoomSeat] {
        let raw: [[CGPoint]]   // avatar anchors per layout
        switch max(1, count) {
        case 1:  raw = [[p(0.50, 0.56)]]
        case 2:  raw = [[p(0.36, 0.56), p(0.64, 0.56)]]
        case 3:  raw = [[p(0.32, 0.50), p(0.68, 0.50), p(0.50, 0.66)]]
        case 4:  raw = [[p(0.30, 0.49), p(0.70, 0.49), p(0.32, 0.68), p(0.68, 0.68)]]
        case 5:  raw = [[p(0.28, 0.47), p(0.50, 0.45), p(0.72, 0.47), p(0.34, 0.67), p(0.66, 0.67)]]
        case 6:  raw = [[p(0.26, 0.47), p(0.50, 0.45), p(0.74, 0.47), p(0.30, 0.66), p(0.50, 0.68), p(0.70, 0.66)]]
        case 7:  raw = [[p(0.24, 0.45), p(0.44, 0.44), p(0.64, 0.44), p(0.80, 0.50), p(0.30, 0.65), p(0.52, 0.67), p(0.72, 0.65)]]
        default: raw = [[p(0.24, 0.45), p(0.44, 0.44), p(0.64, 0.44), p(0.82, 0.49),
                         p(0.22, 0.64), p(0.42, 0.66), p(0.62, 0.66), p(0.80, 0.64)]]
        }
        return raw[0].map { a in
            RoomSeat(avatar: a, desk: p(a.x, a.y + 0.062), scale: scale(for: count))
        }
    }

    private static func scale(for count: Int) -> CGFloat {
        switch count { case 1: return 1.0; case 2...3: return 0.92; case 4...5: return 0.84; default: return 0.74 }
    }

    private static func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
}
