import SwiftUI

// MARK: - DemoFlowView — clickable static prototype of the full design
//
// Walks the complete approved design (Demo01…Demo10) as full-bleed screens.
// Tap anywhere (i.e. the on-image button) to advance. After the final "Room
// complete" screen, loops back to Home so the demo can keep going.
//
// Narrative order:
//  01 splash → 02 welcome → 03 choose avatar → 04 customise → 05 player ready
//  → 06 first room → 07 home → 08 set your lock-in → 09 live focus room
//  → 10 room complete → (loop back to 07 home)

struct DemoFlowView: View {

    // Index of the Home screen (Demo07) — results loop back here.
    private let homeIndex = 6
    private let screens = (1...10).map { String(format: "Demo%02d", $0) }

    @State private var index = 0

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()

            GeometryReader { geo in
                Image(screens[index])
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                    .clipped()
            }
            .ignoresSafeArea()
            .id(index) // fresh transition per screen
            .transition(.opacity)

            // Whole-screen tap target (the on-image buttons advance the flow)
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture { advance() }
        }
        .statusBarHidden(true)
    }

    private func advance() {
        withAnimation(.easeInOut(duration: 0.18)) {
            if index >= screens.count - 1 {
                index = homeIndex          // after "Room complete" → back to Home
            } else {
                index += 1
            }
        }
    }
}

#Preview { DemoFlowView() }
