import SwiftUI

// MARK: - StaticRoomScreen — full-bleed mockup screen, tap to dismiss
//
// Shows an approved design mockup (e.g. SoloRoom, GroupRoom) full-bleed.
// Tap anywhere (or the on-image button) to return.

struct StaticRoomScreen: View {
    let imageName: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()
            GeometryReader { geo in
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
                    .clipped()
            }
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { dismiss() }

            // Honest close affordance (top-right)
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Theme.Colour.appShell.opacity(0.6))
                            .padding(Theme.Spacing.md)
                    }
                }
                Spacer()
            }
        }
        .statusBarHidden(true)
    }
}

#Preview { StaticRoomScreen(imageName: "SoloRoom") }
