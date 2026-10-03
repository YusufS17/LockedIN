import SwiftUI

// MARK: - RoomLayout — pixel-space anchors on the shell canvas
//
// All anchors are canvas coordinates (192×160, RoomSpriteShell.canvas), NOT view
// points. Every anchor is a ground point (bottom-centre of a piece) and sits on
// the floor diamond. `project` maps canvas → view coords for the shell image
// rendered .scaledToFit (the baked image carries a 1px outline margin, so the
// mapping is against the 194×162 image, letterboxed and centred).

/// One seat in a session room: where the avatar stands/sits, where its chair
/// and desk ground, whether the sprites mirror (right-half seats face the room
/// centre), and the sprite scale (back rows shrink for depth).
struct PixelSeat {
    var avatar: CGPoint
    var desk: CGPoint
    var chair: CGPoint
    var facing: Bool      // true = mirrored
    var scale: CGFloat
}

struct RoomLayout {

    /// Baked shell image size = canvas + 2×outline margin.
    static let imageSize = CGSize(width: CGFloat(RoomSpriteShell.canvas.cols + 2),
                                  height: CGFloat(RoomSpriteShell.canvas.rows + 2))

    /// Open foreground aisle: a standing break occupant must not cover a seated face.
    static let breakAnchor = CGPoint(x: 105, y: 149)

    /// Open front-right floor where the hero avatar stands in still rooms
    /// (solo / world / onboarding first-room) — beside the desk, like mockup 04.
    static let heroStand = CGPoint(x: 128, y: 136)

    /// Seat anchors for 1...8 participants, back-to-front. Rows are STAGGERED
    /// horizontally so a front desk never fully hides a back-row participant,
    /// and every desk footprint stays inside the floor diamond (it narrows fast
    /// toward the front corner). Back rows shrink for depth.
    static func seats(_ count: Int) -> [PixelSeat] {
        switch max(1, min(8, count)) {
        case 1: return [seat(96, 112)]
        case 2: return [seat(62, 110), seat(130, 110)]
        case 3: return [seat(58, 98, 0.9), seat(134, 98, 0.9), seat(96, 122)]
        case 4: return [seat(52, 98, 0.82), seat(119, 94, 0.82),
                        seat(79, 124, 0.92), seat(137, 118, 0.86)]
        case 5: return [seat(52, 96, 0.85), seat(96, 90, 0.85), seat(140, 96, 0.85),
                        seat(72, 118), seat(122, 118)]
        case 6: return [seat(52, 96, 0.85), seat(96, 90, 0.85), seat(140, 96, 0.85),
                        seat(64, 118), seat(106, 122), seat(146, 114, 0.9)]
        case 7: return [seat(48, 94, 0.8), seat(96, 88, 0.8), seat(144, 94, 0.8),
                        seat(60, 112, 0.9), seat(132, 112, 0.9),
                        seat(86, 126), seat(114, 124)]
        default: return [seat(48, 94, 0.8), seat(96, 88, 0.8), seat(144, 94, 0.8),
                         seat(60, 110, 0.9), seat(96, 114, 0.9), seat(132, 110, 0.9),
                         seat(88, 128), seat(112, 124)]
        }
    }

    private static func seat(_ x: CGFloat, _ y: CGFloat, _ scale: CGFloat = 1) -> PixelSeat {
        PixelSeat(avatar: CGPoint(x: x, y: y),
                  desk: CGPoint(x: x, y: y + 10 * scale),
                  chair: CGPoint(x: x, y: y + 2 * scale),
                  facing: x > CGFloat(RoomSpriteShell.floorTop.x),
                  scale: scale)
    }

    /// View points per canvas cell for a .scaledToFit shell image.
    static func scale(in viewSize: CGSize) -> CGFloat {
        min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
    }

    /// Canvas coordinate → view coordinate (letterboxed, centred, +1 bake margin).
    static func project(_ p: CGPoint, in viewSize: CGSize) -> CGPoint {
        let s = scale(in: viewSize)
        let ox = (viewSize.width - imageSize.width * s) / 2
        let oy = (viewSize.height - imageSize.height * s) / 2
        return CGPoint(x: ox + (p.x + 1) * s, y: oy + (p.y + 1) * s)
    }
}

// MARK: - RoomComposer — one cached bake of shell + furniture

/// Composes the shell and every furniture sprite into a single 194×162 image,
/// back-to-front, 1px per cell. The whole composition is one SpriteBakery entry
/// keyed on placements + phase + seating, so a still room costs one texture.
enum RoomComposer {

    // Ground/wall anchors (canvas coords, bottom-centre). Wall pieces sit inside
    // the sloped wall bands; floor pieces' bottom rows all land on the diamond.
    private enum Anchor {
        static let window = (x: 43, y: 91)        // left wall
        static let poster = (x: 84, y: 68)        // left wall, right of window
        static let clock = (x: 82, y: 49)         // left wall, up near the corner
        static let pinboard = (x: 163, y: 92)     // right wall
        static let rug = (x: 96, y: 139)
        static let shelf = (x: 125, y: 108)        // floor, against the corner walls
        static let sofa = (x: 51, y: 118)         // floor, under the window
        static let sideTable = (x: 156, y: 120)
        static let plantA = (x: 34, y: 122)       // mirrored, fronting the sofa
        static let plantB = (x: 142, y: 130)
        static let lamp = (x: 58, y: 132)         // arc lamp fronting the sofa
        static let books = (x: 108, y: 144)
    }

    // MARK: Base image

    /// The furnished still room. `includeSeating` adds the single-seat chair +
    /// desk (Solo/World/builder/onboarding); live scenes pass false and layer
    /// chairs/desks/avatars themselves via RoomLayout.seats.
    @MainActor
    static func baseImage(room: PersonalRoom, phase: DayPhase, includeSeating: Bool, sharedStudy: Bool = false) -> UIImage {
        let placements = RoomSlot.allCases.map { room.itemID(for: $0) }.joined(separator: ",")
        let key = "room-base-iso7|\(placements)|\(phase.rawValue)|s\(includeSeating ? 1 : 0)|shared\(sharedStudy ? 1 : 0)"
        return SpriteBakery.shared.image(key: key) {
            compose(room: room, phase: phase, includeSeating: includeSeating, sharedStudy: sharedStudy)
        }
    }

    /// Cached desk piece for live-scene z-sandwiching (chair → avatar → desk).
    @MainActor
    static func deskImage(room: PersonalRoom, mirrored: Bool = false) -> UIImage {
        let item = room.item(for: .desk)
        return RoomDeskSprite.image(variant: item.variant, tint: accentTint(item, slot: .desk), mirrored: mirrored)
    }

    /// Cached chair piece for live-scene z-sandwiching.
    @MainActor
    static func chairImage(room: PersonalRoom, mirrored: Bool = false) -> UIImage {
        let item = room.item(for: .chair)
        return RoomChairSprite.image(variant: item.variant, tint: accentTint(item, slot: .chair), mirrored: mirrored)
    }

    // MARK: Composition

    /// Catalogue thumbnails share the exact palette and variant of the room pieces.
    @MainActor
    static func itemImage(_ item: RoomItem) -> UIImage? {
        let tint = accentTint(item, slot: item.slot)
        switch item.slot {
        case .desk: return RoomDeskSprite.image(variant: item.variant, tint: tint)
        case .chair: return RoomChairSprite.image(variant: item.variant, tint: tint)
        case .lamp: return RoomLampSprite.image(variant: item.variant, tint: tint)
        case .shelf: return RoomShelfSprite.image(variant: item.variant, tint: tint)
        case .plant: return RoomPlantSprite.image(variant: item.variant, tint: tint)
        case .rug: return RoomRugSprite.image(variant: item.variant, tint: tint)
        case .poster: return RoomPosterSprite.image(variant: max(0, item.variant - 1), tint: tint)
        case .window:
            let sky = windowSky(item: item, phase: DayPhase.current())
            return RoomWindowSprite.image(variant: item.variant, sky: sky.sky, accent: sky.accent)
        case .floor, .wall: return nil
        }
    }

    @MainActor
    private static func compose(room: PersonalRoom, phase: DayPhase, includeSeating: Bool, sharedStudy: Bool = false) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false

        return UIGraphicsImageRenderer(size: RoomLayout.imageSize, format: format).image { ctx in
            let cg = ctx.cgContext
            cg.setAllowsAntialiasing(false)
            cg.interpolationQuality = .none

            // Shell — floor/wall tints from the room's floor/wall items.
            RoomSpriteShell.image(
                floorTint: accentTint(room.item(for: .floor), slot: .floor),
                wallTint: accentTint(room.item(for: .wall), slot: .wall),
                phase: phase
            ).draw(at: .zero)

            // Wall pieces, clipped to the sloped wall bands so nothing pokes
            // above the wall top line or below the floor meeting line.
            cg.saveGState()
            cg.addPath(wallClipPath)
            cg.clip()

            let windowItem = room.item(for: .window)
            let sky = windowSky(item: windowItem, phase: phase)
            draw(RoomWindowSprite.image(variant: windowItem.variant, sky: sky.sky,
                                        accent: sky.accent),
                 at: Anchor.window, in: cg, shadow: false)
            draw(RoomClockSprite.image(variant: 0, tint: nil), at: Anchor.clock, in: cg, shadow: false)
            draw(RoomPinboardSprite.image(variant: 0, tint: nil), at: Anchor.pinboard, in: cg, shadow: false)

            let posterItem = room.item(for: .poster)
            if !isNone(posterItem) {
                // Catalog reserves poster variant 0 for "None" — sprite art starts at 0.
                draw(RoomPosterSprite.image(variant: max(0, posterItem.variant - 1),
                                            tint: accentTint(posterItem, slot: .poster)),
                     at: Anchor.poster, in: cg, shadow: false)
            }
            cg.restoreGState()

            // Floor pieces, back-to-front. Rug is flat (no shadow).
            let rugItem = room.item(for: .rug)
            if !isNone(rugItem) {
                draw(RoomRugSprite.image(variant: rugItem.variant, tint: accentTint(rugItem, slot: .rug)),
                     at: Anchor.rug, in: cg, shadow: false)
            }

            let shelfItem = room.item(for: .shelf)
            // Leave a light wall gap behind the rear seated silhouette. The
            // smaller shared shelf remains on the right perimeter, with books
            // and purchased shelf colour intact.
            draw(RoomShelfSprite.image(variant: shelfItem.variant, tint: accentTint(shelfItem, slot: .shelf)),
                 at: sharedStudy ? (143, 105) : Anchor.shelf, in: cg, shadow: true,
                 scale: sharedStudy ? 0.62 : 0.75)
            // Shared study needs clear desk aisles; the sofa remains in the personal room.
            if !sharedStudy {
                draw(RoomSofaSprite.image(variant: 0, tint: nil), at: Anchor.sofa, in: cg, shadow: true)
            }
            draw(RoomSideTableSprite.image(variant: 1, tint: nil),
                 at: sharedStudy ? (164, 113) : Anchor.sideTable, in: cg, shadow: true,
                 scale: sharedStudy ? 0.7 : 1)

            let plantItem = room.item(for: .plant)
            if !isNone(plantItem) {
                let tint = accentTint(plantItem, slot: .plant)
                draw(RoomPlantSprite.image(variant: plantItem.variant, tint: tint, mirrored: true),
                     at: Anchor.plantA, in: cg, shadow: true)
                draw(RoomPlantSprite.image(variant: plantItem.variant, tint: tint),
                     at: sharedStudy ? (174, 120) : Anchor.plantB, in: cg, shadow: true,
                     scale: sharedStudy ? 0.75 : 1)
            }

            let lampItem = room.item(for: .lamp)
            draw(RoomLampSprite.image(variant: lampItem.variant, tint: accentTint(lampItem, slot: .lamp)),
                 at: sharedStudy ? (27, 119) : Anchor.lamp, in: cg, shadow: true,
                 scale: sharedStudy ? 0.8 : 1)
            // Keep the shared foreground aisle free for the standing break occupant.
            // The live break aisle must remain clear in solo and shared rooms.
            // Keep these decorative books in the furnished home/builder view.
            if includeSeating && !sharedStudy {
                draw(RoomBookStackSprite.image(variant: 0, tint: nil), at: Anchor.books, in: cg, shadow: true)
            }

            if includeSeating {
                let seat = RoomLayout.seats(1)[0]
                draw(chairImage(room: room), at: (Int(seat.chair.x), Int(seat.chair.y)), in: cg, shadow: true)
                draw(deskImage(room: room), at: (Int(seat.desk.x), Int(seat.desk.y)), in: cg, shadow: true)
            }
        }
    }

    // MARK: Helpers

    /// Bottom-centre draw at a canvas anchor (+1 bake margin, grid bottom row on
    /// the anchor row). Baked pieces are scale-1 UIImages, so draw(at:) is 1:1.
    private static func draw(_ img: UIImage, at anchor: (x: Int, y: Int), in cg: CGContext, shadow: Bool, scale: CGFloat = 1) {
        let size = CGSize(width: img.size.width * scale, height: img.size.height * scale)
        if shadow {
            let w = size.width * 0.7
            let h = max(3, w * 0.25)
            cg.setFillColor(PixelRGBA(r: 59, g: 42, b: 33).opacity(0.30).uiColor.cgColor)
            cg.fillEllipse(in: CGRect(x: CGFloat(anchor.x) + 1 - w / 2,
                                      y: CGFloat(anchor.y) + 1 - h / 2,
                                      width: w, height: h))
        }
        let ox = (CGFloat(anchor.x) + 1 - size.width / 2).rounded(.down)
        let oy = CGFloat(anchor.y) + 1 + 2 * scale - size.height
        img.draw(in: CGRect(origin: CGPoint(x: ox, y: oy), size: size))
    }

    /// Hexagon over both wall faces (composed coords, +1 margin): sloped top
    /// edges meeting at the corner, floor meeting line below.
    private static var wallClipPath: CGPath {
        let pts: [CGPoint] = [
            CGPoint(x: 8, y: 51), CGPoint(x: 96, y: 7), CGPoint(x: 185, y: 51.5),
            CGPoint(x: 185, y: 116), CGPoint(x: 96, y: 72), CGPoint(x: 8, y: 116),
        ]
        let path = CGMutablePath()
        path.addLines(between: pts.map { CGPoint(x: $0.x + 1, y: $0.y + 1) })
        path.closeSubpath()
        return path
    }

    /// The slot's default (free first) item keeps the authored mockup palette;
    /// any other item recolours the sprite's accent material with its tint.
    private static func accentTint(_ item: RoomItem, slot: RoomSlot) -> Color? {
        item.id == RoomItemCatalog.defaultItem(for: slot).id ? nil : item.tint
    }

    private static func isNone(_ item: RoomItem) -> Bool {
        item.id.hasSuffix(".none")
    }

    /// The window pane sky + accent (clouds/stars/bands material in the sprite).
    /// The free default window follows the real clock's day phase; a bought named
    /// sky ("Dawn", "Aurora") always paints its own scene — that's what was paid for.
    private static func windowSky(item: RoomItem, phase: DayPhase) -> (sky: PixelRGBA, accent: PixelRGBA) {
        if item.id != RoomItemCatalog.defaultItem(for: .window).id {
            switch item.id {
            case "window.dawn":
                return (PixelRGBA(r: 219, g: 158, b: 106), PixelRGBA(r: 255, g: 214, b: 130))
            case "window.aurora":
                return (PixelRGBA(r: 40, g: 78, b: 88), PixelRGBA(r: 155, g: 126, b: 200))
            default:
                let base = phase.skyRamp[1]
                return (DayPhase.mix(base, PixelRGBA(item.tint), 0.30),
                        base.lightened(phase == .night ? 0.70 : 0.50))
            }
        }
        let base = phase.skyRamp[1]
        return (base, base.lightened(phase == .night ? 0.70 : 0.50))
    }
}

#Preview("Room composer") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(DayPhase.allCases, id: \.rawValue) { phase in
                Image(uiImage: RoomComposer.baseImage(room: .seeded, phase: phase, includeSeating: true))
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            }
        }
        .padding()
    }
    .background(Theme.Colour.background)
}
