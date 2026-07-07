import UIKit

// MARK: - SpriteBakery — the bake-once cache
//
// All baked frames live here, keyed by a structural string that embeds everything
// the bake depends on. Key convention:
//   "<domain>|<paletteKey>|<pose>|<status>|<frame>"
// e.g. "av2|H8b5a3cff…|stand|focused|12"
// Appearance changes produce new keys naturally (palette key changes), so there is
// no invalidation logic — stale entries just age out of the NSCache.

@MainActor
final class SpriteBakery {

    static let shared = SpriteBakery()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        // Frames are tiny (3–30KB); 512 entries comfortably covers a full session
        // (8 avatars × ~36 frames) plus room bakes, at a few MB.
        cache.countLimit = 512
    }

    /// Return the cached bake for `key`, or build + cache it.
    func image(key: String, build: () -> UIImage) -> UIImage {
        let nsKey = key as NSString
        if let hit = cache.object(forKey: nsKey) { return hit }
        let img = build()
        cache.setObject(img, forKey: nsKey)
        return img
    }

    func removeAll() { cache.removeAllObjects() }
}
