import UIKit

// MARK: - PixelRenderer — bakes a grid+palette to a tiny UIImage, once
//
// Renders at exactly 1 pixel per cell into a scale-1 bitmap. Display scaling is
// SwiftUI's job (`Image.interpolation(.none)` → crisp nearest-neighbour pixels).
// The outline pass fills empty cells 4-adjacent to filled ones; the fill pass
// applies PixelShader's light model. A baked 24×32 frame is ~3KB; 48×64 is ~12KB.

@MainActor
enum PixelRenderer {

    /// Bake a grid to an image. `outline` draws the silhouette ring (pass nil to skip).
    /// `margin` adds empty cells around the grid so outlines/overhangs have room —
    /// keep 0 for art authored with its own internal margins (the v2 avatar).
    static func bake(grid: PixelGrid,
                     palette: PixelPalette,
                     rules: PixelMaterialRules.Rules,
                     outline: PixelRGBA?,
                     margin: Int = 0) -> UIImage {
        let w = grid.cols + margin * 2
        let h = grid.rows + margin * 2

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: format)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            cg.setAllowsAntialiasing(false)
            cg.interpolationQuality = .none

            func fill(_ x: Int, _ y: Int, _ colour: PixelRGBA) {
                cg.setFillColor(colour.uiColor.cgColor)
                cg.fill(CGRect(x: x + margin, y: y + margin, width: 1, height: 1))
            }

            // Pass 1 — outline: empty cells 4-adjacent to a filled cell.
            if let outline {
                let ring = outline.opacity(0.9)
                for y in (-margin)..<(grid.rows + margin) {
                    for x in (-margin)..<(grid.cols + margin) where rules.isEmpty(grid[x, y]) {
                        let touches = !rules.isEmpty(grid[x - 1, y]) || !rules.isEmpty(grid[x + 1, y])
                            || !rules.isEmpty(grid[x, y - 1]) || !rules.isEmpty(grid[x, y + 1])
                        if touches { fill(x, y, ring) }
                    }
                }
            }

            // Pass 2 — fill with light-aware shading.
            for y in 0..<grid.rows {
                for x in 0..<grid.cols {
                    let ch = grid[x, y]
                    guard let base = palette[ch] else { continue }
                    let colour = rules.isFlat(ch)
                        ? base
                        : PixelShader.shaded(base, level: PixelShader.shadeLevel(grid: grid, x: x, y: y, rules: rules))
                    fill(x, y, colour)
                }
            }
        }
    }
}
