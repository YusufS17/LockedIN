import SwiftUI

// MARK: - PixelSpriteView — cached-frame playback
//
// The display end of PixelKit: swaps pre-baked frames on a TimelineView clock and
// scales them with nearest-neighbour interpolation. This view does NO drawing work
// per frame — every frame is a cache lookup (or a one-off <1ms bake on first sight).
// Animation is gated on `animated` and Reduce Motion; when static, frame 0 shows.

struct PixelSpriteView: View {
    /// Base cache key — everything that identifies this sprite except the frame index.
    let cacheKey: String
    /// Number of frames in the loop. 1 = static.
    let frameCount: Int
    /// Builds frame `i` on cache miss.
    let build: (Int) -> UIImage

    /// Frame clock. 6.25fps matches the v2 renderer's 0.16s tick.
    var fps: Double = 6.25
    var animated: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isAnimating: Bool { animated && !reduceMotion && frameCount > 1 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / fps, paused: !isAnimating)) { tl in
            let frame = isAnimating
                ? Int(tl.date.timeIntervalSinceReferenceDate * fps) % frameCount
                : 0
            Image(uiImage: SpriteBakery.shared.image(key: "\(cacheKey)|\(frame)") { build(frame) })
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        }
    }
}
