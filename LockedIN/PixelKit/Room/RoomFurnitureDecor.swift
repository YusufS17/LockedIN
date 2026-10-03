import SwiftUI

// MARK: - RoomFurnitureDecor — floor decor sprites for the room scene
//
// Bookshelf, floor lamps, potted plants, iso rugs, and a foreground book stack,
// all authored as string grids in the warm wood + cream world of the room
// mockups. Furniture shading is HAND-AUTHORED flat tones (top-left light: 'W'
// tops, 'w' fronts, 'd' right/side faces, 'x' hard edge lines) — the auto light
// shader is deliberately bypassed via `.flatIcon` rules. Every piece bakes once
// through SpriteBakery; grids are ground-anchored at bottom-centre.

// MARK: - Shared tones

/// The decor set's shared material ramp. Wood matches the room mockups' ramp;
/// glow/greens/terracotta are reused across pieces so the set reads as one world.
private enum DecorTone {
    static let woodLight = PixelRGBA(r: 169, g: 120, b: 79)    // #A9784F top faces
    static let wood      = PixelRGBA(r: 139, g: 94,  b: 60)    // #8B5E3C fronts
    static let woodDark  = PixelRGBA(r: 110, g: 70,  b: 41)    // #6E4629 side faces
    static let woodLine  = PixelRGBA(r: 89,  g: 55,  b: 31)    // #59371F edge lines
    static let shelfBack = PixelRGBA(r: 74,  g: 48,  b: 32)    // shelf interior shadow

    static let leafLight = PixelRGBA(r: 99,  g: 154, b: 111)   // #639A6F
    static let leaf      = PixelRGBA(r: 74,  g: 124, b: 89)    // #4A7C59
    static let leafDark  = PixelRGBA(r: 51,  g: 87,  b: 62)

    static let terraLight = PixelRGBA(r: 217, g: 141, b: 91)
    static let terra      = PixelRGBA(r: 196, g: 112, b: 63)
    static let terraDark  = PixelRGBA(r: 154, g: 85,  b: 48)

    static let glowCore = PixelRGBA(r: 255, g: 241, b: 201)    // shade opening
    static let glow     = PixelRGBA(r: 255, g: 214, b: 130)    // #FFD682 amber
    static let halo     = PixelRGBA(r: 255, g: 214, b: 130, a: 110) // floor light pool

    static let goldLight = PixelRGBA(r: 255, g: 211, b: 122)
    static let gold      = PixelRGBA(r: 255, g: 182, b: 38)    // accent gold
    static let goldDark  = PixelRGBA(r: 201, g: 138, b: 18)

    static let cream = PixelRGBA(r: 232, g: 222, b: 201)       // fabric cream #E8DEC9

    // Warm book spine set
    static let bookRust    = PixelRGBA(r: 176, g: 72,  b: 58)
    static let bookOrange  = PixelRGBA(r: 201, g: 124, b: 60)
    static let bookMustard = PixelRGBA(r: 217, g: 168, b: 60)
    static let bookOlive   = PixelRGBA(r: 111, g: 124, b: 62)
    static let bookPlum    = PixelRGBA(r: 124, g: 68,  b: 88)

    static let globeSea      = PixelRGBA(r: 91,  g: 127, b: 166)
    static let globeSeaLight = PixelRGBA(r: 127, g: 160, b: 192)

    /// Warm dark silhouette ring shared by every standing piece.
    static let outline = PixelRGBA(r: 59, g: 42, b: 33)
}

// MARK: - RoomShelfSprite

/// Tall bookshelf: wooden frame, 4 shelves of warm book spines, a gold trophy
/// and a tiny plant (solo mockup). variant 1 = wider + darker wood,
/// variant 2 = globe on the trophy shelf. Any other value = base shelf.
enum RoomShelfSprite {

    // Base 44x70 — trophy on shelf 3, plant top shelf.
    private static let baseArt: [String] = [
        "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
        "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
        "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkrrrkkkkkkkkkkwwwddd",
        "wwwkkkkkkggkkkkkkkkkkkkkkrrrkkkkkkkkkkwwwddd",
        "wwwkkkkkgGGgkkkkkkkkkkkkkrrrmmmkkkkkkkwwwddd",
        "wwwkkkkgGGGGekkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwkkkkegGGgekkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwkkkkkeggekkkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwkkkkQQQQQQkkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwkkkkkqqqqkkkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwkkkkkqqqqkkkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwkkkkkqqqqkkkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkrrrkkkkkkkoookkkkkkkkkkkkkkvvvkwwwddd",
        "wwwkcccrrrkkkkvvvoookkkkrrrkkkkmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrkkkkmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkwwwddd",
        "wwwWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkkkkkkktttttttkkkkkkkkkrrrkkwwwddd",
        "wwwkkpppkkkkkkkkTTTTTTTuukkkkkkkkrrrkkwwwddd",
        "wwwkkpppkkkkkkkkTTTTTTTuukkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkkTTTTTTukkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkkkTTTTukkkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkkkkkTkkkkkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkkkkkTkkkkkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkkktttttkkkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkkTTTTTTTkkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkkuuuuuuukkkkkkvvvrrrkkwwwddd",
        "wwwWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkrrrkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkmmmkkkrrrkkkkpppkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkkkkcccccccckkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkkkkcccccccckkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkkooooooooooookkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkkooooooooooookkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkrrrrrrrrrrrrrrkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkrrrrrrrrrrrrrrkwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    ]

    // variant 1: 50x70, wider interior (extra spines), rendered in darker wood.
    private static let wideArt: [String] = [
        "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
        "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
        "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkrrrkkkkkkkkkkwwwddd",
        "wwwkkkkkkggkkkkkkkkkkkkkkkkkkkkrrrkkkkkkkkkkwwwddd",
        "wwwkkkkkgGGgkkkkkkkkkkkkkkkkkkkrrrmmmkkkkkkkwwwddd",
        "wwwkkkkgGGGGekkkkkkkkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwkkkkegGGgekkkkkkkkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwkkkkkeggekkkkkkkkkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwkkkkQQQQQQkkkkkkkkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwkkkkkqqqqkkkkkkkkkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwkkkkkqqqqkkkkkkkkkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwkkkkkqqqqkkkkkkkkkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkrrrkkkkkkkoookkkkkkkkkkkkkkvvvkkkkkkkwwwddd",
        "wwwkcccrrrkkkkvvvoookkkkrrrkkkkmmmvvvkoookkkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrkkkkmmmvvvkooocccwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkooocccwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkooocccwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkooocccwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkooocccwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkooocccwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkooocccwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkooocccwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkooocccwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkooocccwwwddd",
        "wwwWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkkkkkkkkkktttttttkkkkkkkkkkkkrrrkkwwwddd",
        "wwwkkpppkkkkkkkkkkkTTTTTTTuukkkkkkkkkkkrrrkkwwwddd",
        "wwwkkpppkkkkkkkkkkkTTTTTTTuukkkkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkkkkkTTTTTTukkkkkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkkkkkkTTTTukkkkkkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkkkkkkkkTkkkkkkkkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkkkkkkkkTkkkkkkkkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkkkkkktttttkkkkkkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkkkkkTTTTTTTkkkkkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkkkkkuuuuuuukkkkkkkkkvvvrrrkkwwwddd",
        "wwwWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkrrrkkkkkkkoookkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkmmmkkkrrrkkkkpppoookkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppoookkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppoookkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppoookkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppoookkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppoookkkkkkcccccccckkkkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppoookkkkkkcccccccckkkkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppoookkkkooooooooooookkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppoookkkkooooooooooookkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppoookkkrrrrrrrrrrrrrrkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppoookkkrrrrrrrrrrrrrrkkkwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    ]

    // variant 2: 44x70, globe replaces the trophy.
    private static let globeArt: [String] = [
        "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
        "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
        "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkrrrkkkkkkkkkkwwwddd",
        "wwwkkkkkkggkkkkkkkkkkkkkkrrrkkkkkkkkkkwwwddd",
        "wwwkkkkkgGGgkkkkkkkkkkkkkrrrmmmkkkkkkkwwwddd",
        "wwwkkkkgGGGGekkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwkkkkegGGgekkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwkkkkkeggekkkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwkkkkQQQQQQkkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwkkkkkqqqqkkkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwkkkkkqqqqkkkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwkkkkkqqqqkkkkkkkkkkkkkrrrmmmkvvvkkkwwwddd",
        "wwwWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkrrrkkkkkkkoookkkkkkkkkkkkkkvvvkwwwddd",
        "wwwkcccrrrkkkkvvvoookkkkrrrkkkkmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrkkkkmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkwwwddd",
        "wwwkcccrrrmmmkvvvooopppkrrrccckmmmvvvkwwwddd",
        "wwwWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkkkkkkkkkNNNkkkkkkkkkkkrrrkkwwwddd",
        "wwwkkpppkkkkkkkkkkNNnnnkkkkkkkkkkrrrkkwwwddd",
        "wwwkkpppkkkkkkkkkNggnnnnkkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkknnnnggnkkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkknggnnnnkkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkkknnnnnkkkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkkkknnnkkkkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkkkwwwwwkkkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkkkkwwwkkkkkkkkvvvrrrkkwwwddd",
        "wwwkkpppoookkkkkkkxxxxxkkkkkkkvvvrrrkkwwwddd",
        "wwwWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxwwwddd",
        "wwwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkkkkkkkrrrkkkkkkkkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkmmmkkkrrrkkkkpppkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkkkkkkkkkkkkkkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkkkkcccccccckkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkkkkcccccccckkkkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkkooooooooooookkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkkooooooooooookkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkrrrrrrrrrrrrrrkwwwddd",
        "wwwkkmmmcccrrrkvvvpppkkrrrrrrrrrrrrrrkwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd",
        "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    ]

    static func grid(variant: Int) -> PixelGrid {
        var face: PixelGrid
        switch variant {
        case 1: face = PixelGrid(rows: wideArt)
        case 2: face = PixelGrid(rows: globeArt)
        default: face = PixelGrid(rows: baseArt)
        }
        // Tiny foil rules and paper labels break up the solid spines. Only
        // stamp inside a continuous spine, preserving its silhouette and
        // leaving the shelf's plant, trophy and stacked books untouched.
        let spines: Set<Character> = ["r", "o", "m", "v", "p"]
        for y in [25, 29, 44, 57, 61] {
            for x in 4..<(face.cols - 5) {
                let material = face[x, y]
                guard spines.contains(material), face[x - 1, y] == material,
                      face[x + 1, y] == material else { continue }
                face[x, y] = y == 29 || y == 61 ? "I" : "J"
            }
        }
        return face.isometricFace(rising: false, depth: 8, top: "W", side: "d")
    }

    /// tint recolours the primary book-spine material ('r') only.
    static func palette(variant: Int, tint: PixelRGBA?) -> PixelPalette {
        let darker = variant == 1
        func wood(_ c: PixelRGBA) -> PixelRGBA { darker ? c.darkened(0.15) : c }
        return PixelPalette([
            "W": wood(DecorTone.woodLight), "w": wood(DecorTone.wood),
            "d": wood(DecorTone.woodDark),  "x": wood(DecorTone.woodLine),
            "k": wood(DecorTone.shelfBack),
            "I": PixelRGBA(r: 225, g: 213, b: 184), // worn paper spine labels
            "J": PixelRGBA(r: 204, g: 167, b: 106), // muted foil binding rules
            "r": tint ?? DecorTone.bookRust,
            "o": DecorTone.bookOrange, "m": DecorTone.bookMustard,
            "v": DecorTone.bookOlive,  "c": DecorTone.cream, "p": DecorTone.bookPlum,
            "t": DecorTone.goldLight,  "T": DecorTone.gold,  "u": DecorTone.goldDark,
            "G": DecorTone.leafLight,  "g": DecorTone.leaf,  "e": DecorTone.leafDark,
            "Q": DecorTone.terraLight, "q": DecorTone.terra, "j": DecorTone.terraDark,
            "N": DecorTone.globeSeaLight, "n": DecorTone.globeSea,
        ])
    }

    @MainActor
    static func image(variant: Int, tint: Color?, mirrored: Bool = false) -> UIImage {
        let pal = palette(variant: variant, tint: tint.map(PixelRGBA.init))
        return SpriteBakery.shared.image(key: "room-shelf-binding4|v\(variant)|\(pal.cacheKey)|m\(mirrored ? 1 : 0)") {
            var g = grid(variant: variant)
            if mirrored { g = g.mirrored() }
            return PixelRenderer.bake(grid: g, palette: pal, rules: .flatIcon,
                                      outline: DecorTone.outline, margin: 1)
        }
    }
}

// MARK: - RoomLampSprite

/// Warm glowing floor lamp. variant 2 = desk-height lamp (18x28);
/// anything else = arc floor lamp (22x45) with a light pool under the shade.
enum RoomLampSprite {

    private static let arcArt: [String] = [
        "..............ww......",
        "...........wwwwd......",
        "...........ddddd......",
        "........wwwwAAAAAAAA.h",
        "........dddAAAAAAAAAA.",
        ".....wwwwhAAAAAAAAAAA.",
        ".....dddd.AAAAAAAAAAA.",
        ".....wd....CCCCCCCCCC.",
        ".....wd.....CCCCCCCC..",
        ".....wd..h...........h",
        ".....wd......h....h...",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        ".....wd...............",
        "...WWWWWWWWWW.........",
        "...wwwwwwwwww.........",
        "...wwwwwwwwww.........",
        "...wwwwwwwwww.hhhhhhh.",
        "...xxxxxxxxxxhhhhhhhhh",
    ]

    private static let deskArt: [String] = [
        "...h..........h...",
        "......AAAAAA......",
        ".....AAAAAAAA.....",
        "....AAAAAAAAAA....",
        "....AAAAAAAAAA....",
        "....AAAAAAAAAA....",
        "..h..CCCCCCCC..h..",
        "......CCCCCC......",
        "........wd........",
        ".......hwdh.......",
        "........wd........",
        "........wd........",
        "........wd........",
        "........wd........",
        "........wd........",
        "........wd........",
        "........wd........",
        "........wd........",
        "........wd........",
        "........wd........",
        "........wd........",
        "........wd........",
        "........wd........",
        "........wd........",
        "....WWWWWWWWWW....",
        "....wwwwwwwwww....",
        "....wwwwwwwwww....",
        "....xxxxxxxxxx....",
    ]

    static func grid(variant: Int) -> PixelGrid {
        PixelGrid(rows: variant == 2 ? deskArt : arcArt)
    }

    /// tint recolours the wooden pole + base ('W'/'w'/'d'); the amber glow is fixed.
    static func palette(variant: Int, tint: PixelRGBA?) -> PixelPalette {
        PixelPalette([
            "W": tint?.lightened(0.18) ?? DecorTone.woodLight,
            "w": tint ?? DecorTone.wood,
            "d": tint?.darkened(0.22) ?? DecorTone.woodDark,
            "x": DecorTone.woodLine,
            "A": DecorTone.glow, "C": DecorTone.glowCore, "h": DecorTone.halo,
        ])
    }

    @MainActor
    static func image(variant: Int, tint: Color?, mirrored: Bool = false) -> UIImage {
        let pal = palette(variant: variant, tint: tint.map(PixelRGBA.init))
        return SpriteBakery.shared.image(key: "room-lamp|v\(variant)|\(pal.cacheKey)|m\(mirrored ? 1 : 0)") {
            var g = grid(variant: variant)
            if mirrored { g = g.mirrored() }
            return PixelRenderer.bake(grid: g, palette: pal, rules: .flatIcon,
                                      outline: DecorTone.outline, margin: 1)
        }
    }
}

// MARK: - RoomPlantSprite

/// Potted plant in a terracotta pot. variant 2 = small succulent (16x20);
/// anything else = tall snake plant (24x40) with layered blades.
enum RoomPlantSprite {

    private static let snakeArt: [String] = [
        "...........Gg...........",
        "...........Gg...........",
        "...........Gg...........",
        "...........Gg...........",
        "...........Gg...........",
        "...........Gg..ge.......",
        "...........Gg..ge.......",
        ".......ge..Gg..ge.......",
        ".......ge..Gg..ge.......",
        ".......ge..Gg.ge........",
        ".......ge..Gg.ge........",
        "........ge.Gg.ge.Gg.....",
        "........ge.Gg.ge.Gg.....",
        ".....Gg.ge.Gg.ge.Gg.....",
        ".....Gg.ge.Gg.ge.Gg.....",
        ".....Gg.ge.Gg.ge.Gg.....",
        ".....Gg.ge.Gg.ge.Gg.....",
        ".....Gg.ge.Gg.ge.Gg.....",
        ".....Gg.ge.Gg.ge.Gg.....",
        ".....Gg.ge.Gg.ge.Gg.....",
        ".....Gg.ge.Gg.ge.Gg.....",
        ".....Gg.ge.Gg.ge.Gg.....",
        ".....Gg.ge.Gg.ge.Gg.....",
        ".....Gg.ge.Gg.ge.Gg.....",
        ".....Gg.ge.Gg.ge.Gg.....",
        ".....Gg.ge.Gg.ge.Gg.....",
        ".....Gg.ge.Gg.ge.Gg.....",
        "....QGgQgeQGgQgeQGgQ....",
        "....QQQQQQQQQQQQQQQQ....",
        ".....qqqqqqqqqqqjjj.....",
        ".....qqqqqqqqqqqjjj.....",
        ".....qqqqqqqqqqqjjj.....",
        ".....qqqqqqqqqqqjjj.....",
        ".....qqqqqqqqqqqjjj.....",
        ".....qqqqqqqqqqqjjj.....",
        ".....qqqqqqqqqqqjjj.....",
        ".....qqqqqqqqqqqjjj.....",
        ".....qqqqqqqqqqqjjj.....",
        "......jjjjjjjjjjjj......",
        ".......jjjjjjjjjj.......",
    ]

    private static let succulentArt: [String] = [
        ".......GG.......",
        ".....GGGGGG.....",
        "....ggGGGGgg....",
        "...egggGGggge...",
        "...egggGGggge...",
        "...egggggggge...",
        "...egggggggge...",
        "..egggggggggge..",
        "..egggggggggge..",
        "...egggggggge...",
        "...egggggggge...",
        "..QQQQQQQQQQQQ..",
        "..QQQQQQQQQQQQ..",
        "...qqqqqqqqjj...",
        "...qqqqqqqqjj...",
        "...qqqqqqqqjj...",
        "...qqqqqqqqjj...",
        "...qqqqqqqqjj...",
        "....jjjjjjjj....",
        ".....jjjjjj.....",
    ]

    // Variant 3 "Bloom": flower clusters stamped onto the leaf tips ('f'/'F').
    private static let bloomOverlay: [String] = [
        "........ff....FF........",
        "........ff....FF........",
        ".................ff.....",
        ".................ff.....",
        ".....FF.................",
        ".....FF.................",
    ]

    static func grid(variant: Int) -> PixelGrid {
        switch variant {
        case 2:  // "Cactus" — succulent
            return PixelGrid(rows: succulentArt)
        case 3:  // "Bloom" — fern with tinted flowers at the leaf tips
            var g = PixelGrid(rows: snakeArt)
            g.stamp(PixelGrid(rows: bloomOverlay), atX: 0, y: 0)
            return g
        default:
            return PixelGrid(rows: snakeArt)
        }
    }

    /// tint recolours the terracotta pot ('Q'/'q'/'j'); the greens are fixed.
    /// Variant 3 spends the tint on the FLOWERS instead — the pot stays terracotta,
    /// so the paid "Bloom" reads as a genuinely different plant, not a recolour.
    static func palette(variant: Int, tint: PixelRGBA?) -> PixelPalette {
        if variant == 3 {
            let bloom = tint ?? PixelRGBA(r: 224, g: 107, b: 139)
            return PixelPalette([
                "G": DecorTone.leafLight, "g": DecorTone.leaf, "e": DecorTone.leafDark,
                "f": bloom, "F": bloom.lightened(0.30),
                "Q": DecorTone.terraLight, "q": DecorTone.terra, "j": DecorTone.terraDark,
            ])
        }
        return PixelPalette([
            "G": DecorTone.leafLight, "g": DecorTone.leaf, "e": DecorTone.leafDark,
            "Q": tint?.lightened(0.18) ?? DecorTone.terraLight,
            "q": tint ?? DecorTone.terra,
            "j": tint?.darkened(0.22) ?? DecorTone.terraDark,
        ])
    }

    @MainActor
    static func image(variant: Int, tint: Color?, mirrored: Bool = false) -> UIImage {
        let pal = palette(variant: variant, tint: tint.map(PixelRGBA.init))
        return SpriteBakery.shared.image(key: "room-plant|v\(variant)|\(pal.cacheKey)|m\(mirrored ? 1 : 0)") {
            var g = grid(variant: variant)
            if mirrored { g = g.mirrored() }
            return PixelRenderer.bake(grid: g, palette: pal, rules: .flatIcon,
                                      outline: DecorTone.outline, margin: 1)
        }
    }
}

// MARK: - RoomRugSprite

/// Flat floor rug in the 2:1 iso plane. variant 2 = striped diagonal runner
/// (88x42); anything else = oval rug with border, inner ring and medallion
/// (88x44). The WHOLE rug is the tintable accent, quantised into three tones.
/// No silhouette outline — a rug lies flat on the floor, a dark ring would
/// lift it off the boards; its own 'c' border does the edge work.
enum RoomRugSprite {

    private static let ovalArt: [String] = [
        "......................................cccccccccccc......................................",
        "..............................cccccccccccccccccccccccccccc..............................",
        ".........................cccccccccccccccccccccccccccccccccccccc.........................",
        ".....................cccccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccccc.....................",
        "..................cccccccccbbbbbbbaaaaaaaaaaaaaaaaaaaabbbbbbbccccccccc..................",
        "................ccccccccbbbbbaaaaaaaaabbbbbbbbbbbbaaaaaaaaabbbbbcccccccc................",
        "..............cccccccbbbbaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaabbbbccccccc..............",
        "............ccccccbbbbaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaabbbbcccccc............",
        "..........ccccccbbbbaaaabbbbbbbbbbbbbbbbbbbccbbbbbbbbbbbbbbbbbbbaaaabbbbcccccc..........",
        "........ccccccbbbbaaabbbbbbbbbbbbbbbbbbbbccccccbbbbbbbbbbbbbbbbbbbbaaabbbbcccccc........",
        ".......ccccccbbbaaabbbbbbbbbbbbbbbbbbbbbbccccccbbbbbbbbbbbbbbbbbbbbbbaaabbbcccccc.......",
        "......cccccbbbaaaabbbbbbbbbbbbbbbbbbbbbbbbbccbbbbbbbbbbbbbbbbbbbbbbbbbaaaabbbccccc......",
        ".....cccccbbbaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaabbbccccc.....",
        "....cccccbbbaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaabbbccccc....",
        "...cccccbbbaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaabbbccccc...",
        "..cccccbbbaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaabbbccccc..",
        "..cccccbbaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaabbccccc..",
        ".cccccbbbaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbaaabbbccccc.",
        ".cccccbbaaabbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbaaabbccccc.",
        ".ccccbbbaaabbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaccaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbaaabbbcccc.",
        ".ccccbbbaabbbbbbbbbccbbbbbbbbbbbbbaaaaaaaccccccaaaaaaabbbbbbbbbbbbbccbbbbbbbbbaabbbcccc.",
        ".ccccbbbaabbbbbbbccccccbbbbbbbbbaaaaaaaccccccccccaaaaaaabbbbbbbbbccccccbbbbbbbaabbbcccc.",
        ".ccccbbbaabbbbbbbccccccbbbbbbbbbaaaaaaaccccccccccaaaaaaabbbbbbbbbccccccbbbbbbbaabbbcccc.",
        ".ccccbbbaabbbbbbbbbccbbbbbbbbbbbbbaaaaaaaccccccaaaaaaabbbbbbbbbbbbbccbbbbbbbbbaabbbcccc.",
        ".ccccbbbaaabbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaccaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbaaabbbcccc.",
        ".cccccbbaaabbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbaaabbccccc.",
        ".cccccbbbaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbaaabbbccccc.",
        "..cccccbbaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaabbccccc..",
        "..cccccbbbaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaabbbccccc..",
        "...cccccbbbaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaabbbccccc...",
        "....cccccbbbaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaabbbccccc....",
        ".....cccccbbbaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaabbbccccc.....",
        "......cccccbbbaaaabbbbbbbbbbbbbbbbbbbbbbbbbccbbbbbbbbbbbbbbbbbbbbbbbbbaaaabbbccccc......",
        ".......ccccccbbbaaabbbbbbbbbbbbbbbbbbbbbbccccccbbbbbbbbbbbbbbbbbbbbbbaaabbbcccccc.......",
        "........ccccccbbbbaaabbbbbbbbbbbbbbbbbbbbccccccbbbbbbbbbbbbbbbbbbbbaaabbbbcccccc........",
        "..........ccccccbbbbaaaabbbbbbbbbbbbbbbbbbbccbbbbbbbbbbbbbbbbbbbaaaabbbbcccccc..........",
        "............ccccccbbbbaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaabbbbcccccc............",
        "..............cccccccbbbbaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaabbbbccccccc..............",
        "................ccccccccbbbbbaaaaaaaaabbbbbbbbbbbbaaaaaaaaabbbbbcccccccc................",
        "..................cccccccccbbbbbbbaaaaaaaaaaaaaaaaaaaabbbbbbbccccccccc..................",
        ".....................cccccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccccc.....................",
        ".........................cccccccccccccccccccccccccccccccccccccc.........................",
        "..............................cccccccccccccccccccccccccccc..............................",
        "......................................cccccccccccc......................................",
    ]

    private static let runnerArt: [String] = [
        "............cccc........................................................................",
        "..........cccccccc......................................................................",
        "........cccccaaacccc....................................................................",
        "......cccccaaaaaaacccc..................................................................",
        "....cccccaaaaaaaaaaacccc................................................................",
        "..cccccaaaaaaaaaaabbbbcccc..............................................................",
        "cccccaaaaaaaaaaabbbbbbbbcccc............................................................",
        "..ccccaaaaaaaabbbbbbbbbbbbcccc..........................................................",
        "....ccccaaaabbbbbbbbbbbbbbbbcccc........................................................",
        "......ccccbbbbbbbbbbbbbbbbaaaacccc......................................................",
        "........ccccbbbbbbbbbbbbaaaaaaaacccc....................................................",
        "..........ccccbbbbbbbbaaaaaaaaaaaacccc..................................................",
        "............ccccbbbbaaaaaaaaaaaaaaaacccc................................................",
        "..............ccccaaaaaaaaaaaaaaaabbbbcccc..............................................",
        "................ccccaaaaaaaaaaaabbbbbbbbcccc............................................",
        "..................ccccaaaaaaaabbbbbbbbbbbbcccc..........................................",
        "....................ccccaaaabbbbbbbbbbbbbbbbcccc........................................",
        "......................ccccbbbbbbbbbbbbbbbbaaaacccc......................................",
        "........................ccccbbbbbbbbbbbbaaaaaaaacccc....................................",
        "..........................ccccbbbbbbbbaaaaaaaaaaaacccc..................................",
        "............................ccccbbbbaaaaaaaaaaaaaaaacccc................................",
        "..............................ccccaaaaaaaaaaaaaaaabbbbcccc..............................",
        "................................ccccaaaaaaaaaaaabbbbbbbbcccc............................",
        "..................................ccccaaaaaaaabbbbbbbbbbbbcccc..........................",
        "....................................ccccaaaabbbbbbbbbbbbbbbbcccc........................",
        "......................................ccccbbbbbbbbbbbbbbbbaaaacccc......................",
        "........................................ccccbbbbbbbbbbbbaaaaaaaacccc....................",
        "..........................................ccccbbbbbbbbaaaaaaaaaaaacccc..................",
        "............................................ccccbbbbaaaaaaaaaaaaaaaacccc................",
        "..............................................ccccaaaaaaaaaaaaaaaabbbbcccc..............",
        "................................................ccccaaaaaaaaaaaabbbbbbbbcccc............",
        "..................................................ccccaaaaaaaabbbbbbbbbbbbcccc..........",
        "....................................................ccccaaaabbbbbbbbbbbbbbbbcccc........",
        "......................................................ccccbbbbbbbbbbbbbbbbaaaacccc......",
        "........................................................ccccbbbbbbbbbbbbaaaaaaaacccc....",
        "..........................................................ccccbbbbbbbbaaaaaaaaaaaccccc..",
        "............................................................ccccbbbbaaaaaaaaaaaccccc....",
        "..............................................................ccccaaaaaaaaaaaccccc......",
        "................................................................ccccaaaaaaaccccc........",
        "..................................................................ccccaaaccccc..........",
        "....................................................................cccccccc............",
        "......................................................................cccc..............",
    ]

    static func grid(variant: Int) -> PixelGrid {
        // Catalog: variant 1 = "Amber"/"Teal" (striped runner), variant 2 = the
        // paid "Rose round" — which must actually be the round rug.
        PixelGrid(rows: variant == 2 ? ovalArt : runnerArt)
    }

    /// tint (default fabric cream) split into light 'a' / base 'b' / dark 'c'.
    static func palette(variant: Int, tint: PixelRGBA?) -> PixelPalette {
        let base = tint ?? DecorTone.cream
        return PixelPalette([
            "a": base.lightened(0.30),
            "b": base,
            "c": base.darkened(0.28),
        ])
    }

    @MainActor
    static func image(variant: Int, tint: Color?, mirrored: Bool = false) -> UIImage {
        let pal = palette(variant: variant, tint: tint.map(PixelRGBA.init))
        return SpriteBakery.shared.image(key: "room-rug|v\(variant)|\(pal.cacheKey)|m\(mirrored ? 1 : 0)") {
            var g = grid(variant: variant)
            if mirrored { g = g.mirrored() }
            return PixelRenderer.bake(grid: g, palette: pal, rules: .flatIcon,
                                      outline: nil, margin: 1)
        }
    }
}

// MARK: - RoomBookStackSprite

/// Small floor stack of 3 offset books (solo mockup foreground), 18x12.
/// Single design — `variant` is accepted for API uniformity and ignored.
enum RoomBookStackSprite {

    private static let art: [String] = [
        "...MMMMMMMMMMMMM..",
        "...mmmmmmmmmmmcc..",
        "...mmmmmmmmmmmcc..",
        "...xxxxxxxxxxxxx..",
        ".VVVVVVVVVVVVVVVV.",
        ".vvvvvvvvvvvvvvcc.",
        ".vvvvvvvvvvvvvvcc.",
        ".xxxxxxxxxxxxxxxx.",
        "RRRRRRRRRRRRRRRRRR",
        "rrrrrrrrrrrrrrrrcc",
        "rrrrrrrrrrrrrrrrcc",
        "xxxxxxxxxxxxxxxxxx",
    ]

    static func grid(variant: Int) -> PixelGrid {
        PixelGrid(rows: art)
    }

    /// tint recolours the top book ('M'/'m'); the rest of the stack is fixed.
    static func palette(variant: Int, tint: PixelRGBA?) -> PixelPalette {
        PixelPalette([
            "M": tint?.lightened(0.20) ?? DecorTone.bookMustard.lightened(0.20),
            "m": tint ?? DecorTone.bookMustard,
            "V": DecorTone.bookOlive.lightened(0.20), "v": DecorTone.bookOlive,
            "R": DecorTone.bookRust.lightened(0.20),  "r": DecorTone.bookRust,
            "c": DecorTone.cream, "x": DecorTone.woodLine,
        ])
    }

    @MainActor
    static func image(variant: Int, tint: Color?, mirrored: Bool = false) -> UIImage {
        let pal = palette(variant: variant, tint: tint.map(PixelRGBA.init))
        return SpriteBakery.shared.image(key: "room-books|v\(variant)|\(pal.cacheKey)|m\(mirrored ? 1 : 0)") {
            var g = grid(variant: variant)
            if mirrored { g = g.mirrored() }
            return PixelRenderer.bake(grid: g, palette: pal, rules: .flatIcon,
                                      outline: DecorTone.outline, margin: 1)
        }
    }
}

#Preview("Furniture decor") {
    ScrollView(.horizontal) {
        HStack(alignment: .bottom, spacing: 24) {
            ForEach([0, 1, 2], id: \.self) { v in
                Image(uiImage: RoomShelfSprite.image(variant: v, tint: nil))
                    .interpolation(.none).resizable().scaledToFit().frame(height: 210)
            }
            Image(uiImage: RoomLampSprite.image(variant: 1, tint: nil))
                .interpolation(.none).resizable().scaledToFit().frame(height: 140)
            Image(uiImage: RoomLampSprite.image(variant: 2, tint: nil))
                .interpolation(.none).resizable().scaledToFit().frame(height: 90)
            Image(uiImage: RoomPlantSprite.image(variant: 1, tint: nil))
                .interpolation(.none).resizable().scaledToFit().frame(height: 120)
            Image(uiImage: RoomPlantSprite.image(variant: 2, tint: nil))
                .interpolation(.none).resizable().scaledToFit().frame(height: 64)
            Image(uiImage: RoomRugSprite.image(variant: 1, tint: nil))
                .interpolation(.none).resizable().scaledToFit().frame(width: 260)
            Image(uiImage: RoomRugSprite.image(variant: 2, tint: nil))
                .interpolation(.none).resizable().scaledToFit().frame(width: 260)
            Image(uiImage: RoomBookStackSprite.image(variant: 0, tint: nil))
                .interpolation(.none).resizable().scaledToFit().frame(height: 40)
        }
        .padding()
    }
    .background(Color(red: 0.957, green: 0.922, blue: 0.847))
}
