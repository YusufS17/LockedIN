import SwiftUI

// MARK: - LiveRoomScene — the multi-desk squad study room (v3 pixel art)
//
// The shared study room as a real, occupied space: the furnished room is ONE baked
// `RoomComposer` texture (no seating), and every participant is layered on top at a
// `RoomLayout` seat — chair → seated body → desk → working hands, so the desk's front
// face occludes the avatar's lap while the hands rest on top. All positions go through `RoomLayout.project`, and
// sprite sizes derive from `RoomLayout.scale(in:)`, so the cast scales with the room.
//
// Compact icon status badges sit above each head (non-idle only); a
// player on a break stands at `RoomLayout.breakAnchor` with the coffee pose.

struct LiveRoomScene: View {
    let participants: [SessionParticipant]
    let room: PersonalRoom
    /// Index (into `participants`) of the user when on a break — drawn in the break corner.
    var breakingUserIndex: Int?

    @State private var selectedArea = 0

    private var areas: [[Int]] { StudyAreaLayout.indices(participantCount: participants.count) }
    private var visibleIndices: [Int] {
        guard !areas.isEmpty else { return [] }
        return areas[min(selectedArea, areas.count - 1)]
    }

    @ReducedMotionPreference private var reduceMotion

    var body: some View {
        VStack(spacing: 8) {
            roomScene
                .aspectRatio(RoomLayout.imageSize.width / RoomLayout.imageSize.height, contentMode: .fit)
            if areas.count > 1 { areaControls }
        }
        .onAppear { showUserArea() }
        .onChange(of: breakingUserIndex) { _, index in
            if let index, let area = StudyAreaLayout.area(containing: index, participantCount: participants.count) {
                selectedArea = area
            }
        }
        .onChange(of: participants.count) { _, _ in showUserArea() }
    }

    private var areaControls: some View {
        HStack(spacing: 4) {
            ForEach(areas.indices, id: \.self) { area in
                Button { selectedArea = area } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(selectedArea == area ? Theme.Colour.focusGreen : Theme.Colour.textSecondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Area \(area + 1)").font(.system(size: 12, weight: .semibold))
                            Text("\(areas[area].count) people\(areas[area].contains(where: { participants[$0].isUser }) ? " · You" : "")")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.Colour.textSecondary)
                        }
                        Spacer(minLength: 0)
                        if selectedArea == area {
                            Image(systemName: "checkmark").font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.Colour.focusGreen)
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(selectedArea == area ? Theme.Colour.surface : .clear,
                                in: RoundedRectangle(cornerRadius: 11))
                    .overlay {
                        RoundedRectangle(cornerRadius: 11)
                            .strokeBorder(selectedArea == area ? Theme.Colour.cardBorder : .clear, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("study.area.\(area + 1)")
                .accessibilityAddTraits(selectedArea == area ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Theme.Colour.surfaceMid.opacity(0.7), in: RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal, 14)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Study areas")
    }

    private func showUserArea() {
        let userIndex = participants.firstIndex(where: { $0.isUser }) ?? 0
        selectedArea = StudyAreaLayout.area(containing: userIndex, participantCount: participants.count) ?? 0
    }

    private var roomScene: some View {
        GeometryReader { geo in
            let s = geo.size
            let cell = RoomLayout.scale(in: s)
            let seats = RoomLayout.seats(visibleIndices.count)

            ZStack {
                // Fill behind the letterbox (canvas ~1.2:1 vs arbitrary containers).
                Theme.Colour.background

                Image(uiImage: RoomComposer.baseImage(room: room,
                                                      phase: DayPhase.current(),
                                                      includeSeating: false,
                                                      sharedStudy: participants.count > 1))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: s.width, height: s.height)

                // Participants, back-to-front for correct overlap.
                ForEach(orderedSeating(seats), id: \.0) { i, seat in
                    seatUnit(participant: participants[i], seat: seat, in: s, cell: cell,
                             occupied: i != breakingUserIndex)
                }

                // A break moves the person, not their furniture. Draw the standing
                // occupant after the seated rows because this anchor is foreground.
                if let index = breakingUserIndex, visibleIndices.contains(index) {
                    breakUnit(participants[index], in: s, cell: cell)
                }

                RoomAmbientLayer(
                    size: s, room: room, reduceMotion: reduceMotion,
                    lampAt: RoomCanvas.fraction(RoomCanvas.lampGlow(room: room, sharedStudy: participants.count > 1), in: s),
                    windowAt: RoomCanvas.fraction(RoomCanvas.windowGlow, in: s)
                )
            }
        }
    }

    /// Pair each participant with a seat, ordered back (small y) to front for draw order.
    private func orderedSeating(_ seats: [PixelSeat]) -> [(Int, PixelSeat)] {
        zip(visibleIndices, seats)
            .map { ($0.0, $0.1) }
            .sorted { $0.1.avatar.y < $1.1.avatar.y }
    }

    // MARK: - One seat: chair → avatar → desk → working hands

    /// Mockup proportion: a seated character reads ≈1/4 of the room height,
    /// so the 48×64 sprite renders at 48 canvas cells tall (not its native 64).
    private static let avatarCells: CGFloat = 48
    /// Desks/chairs in the live scene shrink slightly so the cast stays the hero.
    private static let furnitureScale: CGFloat = 0.8

    @MainActor
    private func seatUnit(participant p: SessionParticipant, seat: PixelSeat,
                          in size: CGSize, cell: CGFloat, occupied: Bool = true) -> some View {
        let avatarSize = Self.avatarCells * cell * seat.scale
        let ground = RoomLayout.project(seat.avatar, in: size)
        let groundOffset = 2 * cell * seat.scale   // bake-margin row below the anchor

        return ZStack {
            piece(RoomComposer.chairImage(room: room, mirrored: seat.facing),
                  anchor: seat.chair, pieceScale: seat.scale * Self.furnitureScale,
                  in: size, cell: cell)

            if occupied {
                PixelAvatarView(appearance: p.character.fallback, status: p.status,
                           size: avatarSize, pose: .sitTypingFront)
                    .scaleEffect(x: seat.facing ? -1 : 1, y: 1)
                    .position(x: ground.x, y: ground.y + groundOffset - avatarSize / 2)
            }

            piece(RoomComposer.deskImage(room: room, mirrored: seat.facing),
                  anchor: seat.desk, pieceScale: seat.scale * Self.furnitureScale,
                  in: size, cell: cell)

            if occupied {
                PixelAvatarView(appearance: p.character.fallback, status: p.status,
                                size: avatarSize, pose: .sitTypingFront, layer: .deskHands)
                    .scaleEffect(x: seat.facing ? -1 : 1, y: 1)
                    .position(x: ground.x, y: ground.y + groundOffset - avatarSize / 2)
                    .accessibilityHidden(true)

                statusTag(p.status)
                    .fixedSize()
                    .position(statusPosition(for: seat, status: p.status, in: size, cell: cell))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(occupied ? "\(p.isUser ? "You" : p.displayName), \(p.status.label)" : "Empty study desk")
    }

    @MainActor
    private func breakUnit(_ p: SessionParticipant, in size: CGSize, cell: CGFloat) -> some View {
        let avatarSize = Self.avatarCells * cell
        let ground = RoomLayout.project(RoomLayout.breakAnchor, in: size)
        return ZStack {
            PixelAvatarView(appearance: p.character.fallback, status: .onBreak,
                       size: avatarSize, pose: .coffee)
                .position(x: ground.x, y: ground.y + 2 * cell - avatarSize / 2)
            // The foreground person's head is near the front seated row.
            // Put this label beside their body, away from every seated face.
            statusTag(.onBreak)
                .fixedSize()
                .position(x: ground.x + avatarSize * 0.62,
                          y: ground.y - avatarSize * 0.30)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(p.isUser ? "You" : p.displayName), on break")
    }

    /// A baked furniture piece drawn bottom-centre on a canvas ground anchor,
    /// matching `RoomComposer`'s in-bake alignment (art bottom row on the anchor row).
    private func piece(_ img: UIImage, anchor: CGPoint, pieceScale: CGFloat,
                       in size: CGSize, cell: CGFloat) -> some View {
        let w = img.size.width * cell * pieceScale
        let h = img.size.height * cell * pieceScale
        let p = RoomLayout.project(anchor, in: size)
        return Image(uiImage: img)
            .interpolation(.none)
            .resizable()
            .frame(width: w, height: h)
            .position(x: p.x, y: p.y + 2 * cell * pieceScale - h / 2)
    }

    // MARK: - Compact scene labels

    /// Clear neighbouring heads using the projected geometry, not a seat index.
    /// Fixed-size status badges keep the cast unobstructed; readable status text
    /// lives in the roster and each occupant’s accessibility label.
    private func statusPosition(for seat: PixelSeat, status: AvatarStatus, in size: CGSize, cell: CGFloat) -> CGPoint {
        let avatarSize = Self.avatarCells * cell * seat.scale
        let ground = RoomLayout.project(seat.avatar, in: size)
        let y = ground.y + 2 * cell * seat.scale - avatarSize - 9
        let halfWidth: CGFloat = 11
        let halfHeight: CGFloat = 11
        let gap: CGFloat = 3
        let roomLeft = (size.width - RoomLayout.imageSize.width * cell) / 2
        let minX = roomLeft + halfWidth + gap
        let maxX = max(minX, size.width - roomLeft - halfWidth - gap)
        func clamped(_ x: CGFloat) -> CGFloat { min(maxX, max(minX, x)) }

        var heads: [CGRect] = []
        for (index, other) in zip(visibleIndices, RoomLayout.seats(visibleIndices.count)) {
            guard index != breakingUserIndex, other.avatar != seat.avatar else { continue }
            let height = Self.avatarCells * cell * other.scale
            let point = RoomLayout.project(other.avatar, in: size)
            let pixelScale = height / CGFloat(AvatarSpriteV3.rows)
            let spriteLeft = point.x - CGFloat(AvatarSpriteV3.cols) * pixelScale / 2
            let spriteTop = point.y + 2 * cell * other.scale - height
            let rows = SeatedHeadBounds.rows(appearance: participants[index].character.fallback,
                                              status: participants[index].status)
            // Only the occupied silhouette at the tag's vertical band can collide.
            // A single full-head box wrongly fills the space beside a tapered jaw.
            for row in rows {
                let top = spriteTop + row.minY * pixelScale
                let bottom = spriteTop + row.maxY * pixelScale
                guard y + halfHeight + gap > top,
                      y - halfHeight - gap < bottom else { continue }
                let left = other.facing ? CGFloat(AvatarSpriteV3.cols) - row.maxX : row.minX
                heads.append(CGRect(x: spriteLeft + left * pixelScale, y: top,
                                    width: row.width * pixelScale, height: pixelScale))
            }
        }
        var candidates: [CGFloat] = [clamped(ground.x)]
        for head in heads {
            candidates.append(clamped(head.minX - halfWidth - gap))
            candidates.append(clamped(head.maxX + halfWidth + gap))
        }
        candidates.sort { abs($0 - ground.x) < abs($1 - ground.x) }
        let clearX = candidates.first { x in
            heads.allSatisfy { head in
                x + halfWidth + gap <= head.minX || x - halfWidth - gap >= head.maxX
            }
        }
        return CGPoint(x: clearX ?? clamped(ground.x), y: y)
    }

    @ViewBuilder
    private func statusTag(_ status: AvatarStatus) -> some View {
        if status != .idle {
            Image(systemName: status.symbolName ?? "circle.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(statusTint(status))
                .frame(width: 22, height: 22)
                .background(Theme.Colour.surface, in: RoundedRectangle(cornerRadius: 7))
                .overlay {
                    RoundedRectangle(cornerRadius: 7)
                        .strokeBorder(statusTint(status).opacity(0.5), lineWidth: 1)
                }
                .shadow(color: Theme.Colour.textPrimary.opacity(0.12), radius: 0, x: 0, y: 2)
                .accessibilityLabel(status.label)
        }
    }

    private func statusTint(_ status: AvatarStatus) -> Color {
        switch status {
        case .focused: return Theme.Colour.focusGreen
        case .deepFocus: return Theme.Colour.deepFocusBlue
        case .onBreak, .finished: return Theme.Colour.accent
        case .distracted: return Theme.Colour.forfeitRed
        case .idle: return Theme.Colour.textSecondary
        }
    }
}

/// Grid-space head row spans include the renderer's one-pixel silhouette outline.
/// Seated typing/blink animation changes interior materials, not these bounds.
/// The small cache avoids rebuilding grids during timer-driven view updates.
@MainActor
private enum SeatedHeadBounds {
    private static var cache: [String: [CGRect]] = [:]

    static func rows(appearance a: CharacterAppearance, status: AvatarStatus) -> [CGRect] {
        let key = "\(a.skinTone).\(a.hairStyle).\(a.hairColour).\(a.faceStyle).\(a.topStyle).\(a.bottomStyle).\(a.shoeStyle).\(a.accentColour).\(a.accessory)|\(status)"
        if let existing = cache[key] { return existing }
        let grid = AvatarSpriteV3.grid(appearance: a, pose: .sitTypingFront, status: status)
        func filled(_ x: Int, _ y: Int) -> Bool {
            // Face/head rows only; row 26 may contain the outline of row 25.
            guard (0..<26).contains(y), (0..<grid.cols).contains(x) else { return false }
            return grid[x, y] != "."
        }
        var spans: [CGRect] = []
        for y in 0...26 {
            var minimum: Int?
            var maximum = 0
            for x in 0..<grid.cols {
                let occupied = filled(x, y) || filled(x - 1, y) || filled(x + 1, y)
                    || filled(x, y - 1) || filled(x, y + 1)
                if occupied {
                    minimum = minimum ?? x
                    maximum = x
                }
            }
            if let minimum {
                spans.append(CGRect(x: minimum, y: y, width: maximum - minimum + 1, height: 1))
            }
        }
        if cache.count >= 128 { cache.removeAll(keepingCapacity: true) }
        cache[key] = spans
        return spans
    }
}

// MARK: - Preview

#Preview("Live room — 4 seats") {
    ZStack {
        Theme.Colour.background.ignoresSafeArea()
        LiveRoomScene(
            participants: [
                SessionParticipant(character: CharacterCatalog.character(id: "maya"),
                                   displayName: "Maya", isUser: true,
                                   distractions: 0, leftEarly: false, focusPct: 97, status: .deepFocus),
                SessionParticipant(character: CharacterCatalog.character(id: "leo"),
                                   displayName: "Leo", isUser: false,
                                   distractions: 1, leftEarly: false, focusPct: 88, status: .focused),
                SessionParticipant(character: CharacterCatalog.character(id: "sam"),
                                   displayName: "Sam", isUser: false,
                                   distractions: 3, leftEarly: false, focusPct: 61, status: .distracted),
                SessionParticipant(character: CharacterCatalog.character(id: "ada"),
                                   displayName: "Ada", isUser: false,
                                   distractions: 0, leftEarly: false, focusPct: 95, status: .onBreak),
            ],
            room: .seeded,
            breakingUserIndex: 3
        )
        .frame(height: 380)
        .padding()
    }
}
