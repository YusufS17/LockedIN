import Foundation

// MARK: - PixelShader — procedural top-left light model
//
// Every cell is tinted by an implied top-left light: top/left edges of a form catch
// light, bottom/right edges fall to shadow. "Form" boundaries are material GROUPS
// (skin vs hair vs outfit …), so shading wraps around whole shapes rather than
// individual pixels. Extracted verbatim from the v2 avatar renderer so baked output
// matches the old per-frame Canvas output exactly.

enum PixelShader {

    /// Shade level for a cell: -2 (deep shadow) … +2 (bright highlight).
    static func shadeLevel(grid: PixelGrid, x: Int, y: Int, rules: PixelMaterialRules.Rules) -> Int {
        let g = rules.group(grid[x, y])
        func diff(_ nx: Int, _ ny: Int) -> Bool { rules.group(grid[nx, ny]) != g }
        var level = 0
        if diff(x, y + 1) { level -= 2 }   // bottom edge → shadow
        if diff(x, y - 1) { level += 2 }   // top edge → highlight
        if diff(x + 1, y) { level -= 1 }   // right edge → shadow
        if diff(x - 1, y) { level += 1 }   // left edge → highlight
        return max(-2, min(2, level))
    }

    /// Apply a shade level to a base colour. Steps match the v2 renderer.
    static func shaded(_ base: PixelRGBA, level: Int) -> PixelRGBA {
        switch level {
        case 2:   return base.lightened(0.30)
        case 1:   return base.lightened(0.15)
        case -1:  return base.darkened(0.16)
        case -2:  return base.darkened(0.30)
        default:  return base
        }
    }
}
