// Offscreen inspection only. The iOS target does not compile this file.
// Adapts the small UIKit bitmap surface used by PixelKit to CoreGraphics on Mac.
import AppKit
import SwiftUI
import ImageIO
import UniformTypeIdentifiers

typealias UIColor = NSColor

extension Image {
    init(uiImage: UIImage) {
        self.init(decorative: uiImage.cgImage, scale: 1, orientation: .up)
    }
}

private enum RasterContext { static var stack: [CGContext] = [] }

final class UIImage {
    let cgImage: CGImage
    let size: CGSize
    init(_ image: CGImage, size: CGSize) { cgImage = image; self.size = size }

    func draw(at point: CGPoint) {
        draw(in: CGRect(origin: point, size: size))
    }
    func draw(in rect: CGRect) {
        let cg = RasterContext.stack.last!
        cg.saveGState()
        cg.translateBy(x: rect.minX, y: rect.maxY)
        cg.scaleBy(x: 1, y: -1)
        cg.draw(cgImage, in: CGRect(origin: .zero, size: rect.size))
        cg.restoreGState()
    }
    func save(to path: String) throws {
        let url = URL(fileURLWithPath: path)
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(dest, cgImage, nil)
        guard CGImageDestinationFinalize(dest) else { throw CocoaError(.fileWriteUnknown) }
    }
}

final class UIGraphicsImageRendererFormat { var scale: CGFloat = 1; var opaque = false }
struct UIGraphicsImageRendererContext { let cgContext: CGContext }
@MainActor
struct UIGraphicsImageRenderer {
    let size: CGSize
    let format: UIGraphicsImageRendererFormat
    func image(actions: (UIGraphicsImageRendererContext) -> Void) -> UIImage {
        let w = Int(size.width * format.scale), h = Int(size.height * format.scale)
        let cg = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                           space: CGColorSpace(name: CGColorSpace.sRGB)!,
                           bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        cg.translateBy(x: 0, y: CGFloat(h))
        cg.scaleBy(x: format.scale, y: -format.scale)
        cg.interpolationQuality = .none
        RasterContext.stack.append(cg)
        defer { RasterContext.stack.removeLast() }
        actions(UIGraphicsImageRendererContext(cgContext: cg))
        return UIImage(cg.makeImage()!, size: size)
    }
}

@main
struct ArtPreview {
    @MainActor static func main() throws {
        let output = CommandLine.arguments[1]
        let room = RoomComposer.baseImage(room: .seeded, phase: .evening, includeSeating: true)
        try room.save(to: output + "/room-native.png")
        let appearances: [CharacterAppearance] = [.default, .maya, .leo, .sam]
        let avatars = appearances.map { appearance in
            PixelRenderer.bake(grid: AvatarSpriteV3.grid(appearance: appearance),
                               palette: .avatarV3(appearance), rules: .avatarV3, outline: PixelRGBA(r: 31, g: 23, b: 20))
        }
        let format = UIGraphicsImageRendererFormat()
        let board = UIGraphicsImageRenderer(size: CGSize(width: 1164, height: 1040), format: format).image { ctx in
            ctx.cgContext.setFillColor(NSColor(red: 0.973, green: 0.953, blue: 0.914, alpha: 1).cgColor)
            ctx.cgContext.fill(CGRect(x: 0, y: 0, width: 1164, height: 1040))
            room.draw(in: CGRect(x: 97, y: 0, width: 970, height: 810))
            for (i, avatar) in avatars.enumerated() {
                avatar.draw(in: CGRect(x: 100 + i * 250, y: 790, width: 144, height: 192))
                try? avatar.save(to: output + "/avatar-\(i)-native.png")
            }
        }
        try board.save(to: output + "/current-art-board.png")
        // Compare preserved wardrobe axes in standing and both seated directions.
        var separateGarments = CharacterAppearance.default
        separateGarments.topStyle = .jacket
        separateGarments.bottomStyle = .skirt
        separateGarments.shoeStyle = .boots
        let poseAppearances = appearances + [separateGarments]
        let poses = UIGraphicsImageRenderer(size: CGSize(width: 1100, height: 810), format: format).image { ctx in
            ctx.cgContext.setFillColor(NSColor(red: 0.973, green: 0.953, blue: 0.914, alpha: 1).cgColor)
            ctx.cgContext.fill(CGRect(x: 0, y: 0, width: 1100, height: 810))
            for row in 0..<3 {
                for (column, appearance) in poseAppearances.enumerated() {
                    var grid = AvatarSpriteV3.grid(appearance: appearance,
                        pose: row == 0 ? .stand : .sitTypingFront, status: .focused)
                    if row == 2 { grid = grid.mirrored() }
                    let sprite = PixelRenderer.bake(grid: grid, palette: .avatarV3(appearance),
                        rules: .avatarV3, outline: PixelRGBA(r: 31, g: 23, b: 20))
                    sprite.draw(in: CGRect(x: 14 + column * 220, y: 8 + row * 270, width: 192, height: 256))
                }
            }
        }
        try poses.save(to: output + "/avatar-pose-family.png")
        // Rows: none/glasses/headphones/cap/beanie. Columns: all six hair styles.
        let accessories = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1140), format: format).image { ctx in
            ctx.cgContext.setFillColor(NSColor(red: 0.973, green: 0.953, blue: 0.914, alpha: 1).cgColor)
            ctx.cgContext.fill(CGRect(x: 0, y: 0, width: 1080, height: 1140))
            for (row, accessory) in Accessory.allCases.enumerated() {
                for (column, hair) in HairStyle.allCases.enumerated() {
                    var appearance = CharacterAppearance.default
                    appearance.hairStyle = hair
                    appearance.accessory = accessory
                    appearance.skinTone = SkinTone.allCases[column % SkinTone.allCases.count]
                    let sprite = PixelRenderer.bake(grid: AvatarSpriteV3.grid(appearance: appearance),
                        palette: .avatarV3(appearance), rules: .avatarV3, outline: PixelRGBA(r: 31, g: 23, b: 20))
                    sprite.draw(in: CGRect(x: 12 + column * 180, y: 8 + row * 228, width: 156, height: 208))
                }
            }
        }
        try accessories.save(to: output + "/avatar-hair-accessories.png")
        // Rows: stand/type/coffee/phone/celebrate. Columns: all six hairstyles.
        let gestures = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1140), format: format).image { ctx in
            ctx.cgContext.setFillColor(NSColor(red: 0.973, green: 0.953, blue: 0.914, alpha: 1).cgColor)
            ctx.cgContext.fill(CGRect(x: 0, y: 0, width: 1080, height: 1140))
            for (row, pose) in AvatarPose.allCases.enumerated() {
                for (column, hair) in HairStyle.allCases.enumerated() {
                    var appearance = CharacterAppearance.default
                    appearance.hairStyle = hair
                    appearance.topStyle = TopStyle.allCases[column % TopStyle.allCases.count]
                    let sprite = PixelRenderer.bake(grid: AvatarSpriteV3.grid(appearance: appearance, pose: pose),
                        palette: .avatarV3(appearance), rules: .avatarV3, outline: PixelRGBA(r: 31, g: 23, b: 20))
                    sprite.draw(in: CGRect(x: 12 + column * 180, y: 8 + row * 228, width: 156, height: 208))
                }
            }
        }
        try gestures.save(to: output + "/avatar-gesture-family.png")
        // Every independent top/bottom pair, cycling shoes and outfit palettes.
        let wardrobe = UIGraphicsImageRenderer(size: CGSize(width: 900, height: 1140), format: format).image { ctx in
            ctx.cgContext.setFillColor(NSColor(red: 0.973, green: 0.953, blue: 0.914, alpha: 1).cgColor)
            ctx.cgContext.fill(CGRect(x: 0, y: 0, width: 900, height: 1140))
            for (row, bottom) in BottomStyle.allCases.enumerated() {
                for (column, top) in TopStyle.allCases.enumerated() {
                    var appearance = CharacterAppearance.default
                    appearance.topStyle = top
                    appearance.bottomStyle = bottom
                    appearance.shoeStyle = ShoeStyle.allCases[(row + column) % ShoeStyle.allCases.count]
                    appearance.accentColour = AccentColour.allCases[(row * 5 + column) % AccentColour.allCases.count]
                    appearance.faceStyle = FaceStyle.allCases[column]
                    let sprite = PixelRenderer.bake(grid: AvatarSpriteV3.grid(appearance: appearance),
                        palette: .avatarV3(appearance), rules: .avatarV3, outline: PixelRGBA(r: 31, g: 23, b: 20))
                    sprite.draw(in: CGRect(x: 12 + column * 180, y: 8 + row * 228, width: 156, height: 208))
                }
            }
        }
        try wardrobe.save(to: output + "/avatar-wardrobe-family.png")
        // All chair upgrades remain distinct and keep their saved tint support.
        let furniture = UIGraphicsImageRenderer(size: CGSize(width: 660, height: 250), format: format).image { ctx in
            ctx.cgContext.setFillColor(NSColor(red: 0.973, green: 0.953, blue: 0.914, alpha: 1).cgColor)
            ctx.cgContext.fill(CGRect(x: 0, y: 0, width: 660, height: 250))
            for variant in 0...2 {
                let chair = RoomChairSprite.image(variant: variant, tint: nil)
                chair.draw(in: CGRect(x: 40 + CGFloat(variant) * 210, y: 220 - chair.size.height * 5,
                                      width: chair.size.width * 5, height: chair.size.height * 5))
            }
        }
        try furniture.save(to: output + "/chair-variants.png")
        // Mirrors LiveRoomScene's current ground anchors, scale and layer order.
        // No status badges, text, shadows or animated SwiftUI effects are included.
        for breaking in [false, true] {
            let preview = UIGraphicsImageRenderer(size: RoomLayout.imageSize, format: format).image { _ in
                RoomComposer.baseImage(room: .seeded, phase: .evening, includeSeating: false, sharedStudy: true).draw(at: .zero)
                let seats = RoomLayout.seats(4)
                func piece(_ image: UIImage, anchor: CGPoint, scale: CGFloat) {
                    let point = RoomLayout.project(anchor, in: RoomLayout.imageSize)
                    image.draw(in: CGRect(x: point.x - image.size.width * scale / 2,
                                          y: point.y + 2 * scale - image.size.height * scale,
                                          width: image.size.width * scale, height: image.size.height * scale))
                }
                for i in seats.indices.sorted(by: { seats[$0].avatar.y < seats[$1].avatar.y }) {
                    let seat = seats[i]
                    piece(RoomComposer.chairImage(room: .seeded, mirrored: seat.facing), anchor: seat.chair, scale: seat.scale * 0.8)
                    @MainActor func avatar(_ layer: AvatarRenderLayer) {
                        var grid = AvatarSpriteV3.grid(appearance: appearances[i], pose: .sitTypingFront,
                                                      status: .focused, layer: layer)
                        if seat.facing { grid = grid.mirrored() }
                        let sprite = PixelRenderer.bake(grid: grid, palette: .avatarV3(appearances[i]),
                                                        rules: .avatarV3, outline: layer == .deskHands ? nil : PixelRGBA(r: 31, g: 23, b: 20))
                        let point = RoomLayout.project(seat.avatar, in: RoomLayout.imageSize)
                        let height = 48 * seat.scale
                        let width = height * sprite.size.width / sprite.size.height
                        sprite.draw(in: CGRect(x: point.x - width / 2, y: point.y + 2 * seat.scale - height,
                                               width: width, height: height))
                    }
                    if !(breaking && i == 0) { avatar(.full) }
                    piece(RoomComposer.deskImage(room: .seeded, mirrored: seat.facing), anchor: seat.desk, scale: seat.scale * 0.8)
                    if !(breaking && i == 0) { avatar(.deskHands) }
                }
                if breaking {
                    let sprite = PixelRenderer.bake(grid: AvatarSpriteV3.grid(appearance: appearances[0], pose: .coffee, status: .onBreak), palette: .avatarV3(appearances[0]), rules: .avatarV3, outline: PixelRGBA(r: 31, g: 23, b: 20))
                    let point = RoomLayout.project(RoomLayout.breakAnchor, in: RoomLayout.imageSize)
                    sprite.draw(in: CGRect(x: point.x - 18, y: point.y + 2 - 48, width: 36, height: 48))
                }
            }
            let large = UIGraphicsImageRenderer(size: CGSize(width: 970, height: 810), format: format).image { _ in
                preview.draw(in: CGRect(x: 0, y: 0, width: 970, height: 810))
            }
            try large.save(to: output + (breaking ? "/group-break-art.png" : "/group-focus-art.png"))
        }
        print("Exported PixelKit art and a group layering study. These are not iPhone UI screenshots.")
    }
}
