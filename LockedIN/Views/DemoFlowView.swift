import SwiftUI

// MARK: - DemoFlowView — clickable static prototype of the full design
//
// Walks the complete approved design (Demo01…Demo10) as full-bleed screens with a
// smooth paged slide transition. Tap anywhere (i.e. the on-image button) to advance;
// swipe works too. After the final "Room complete" screen, loops back to Home.
//
// Narrative order:
//  01 splash → 02 welcome → 03 choose avatar → 04 customise → 05 player ready
//  → 06 first room → 07 home → 08 set your lock-in → 09 live focus room
//  → 10 room complete → (loop back to 07 home)

struct DemoFlowView: View {

    private let homeIndex = 6                     // Demo07 (Home)
    private let screens = (1...10).map { String(format: "Demo%02d", $0) }

    @State private var index = 0

    var body: some View {
        TabView(selection: $index) {
            ForEach(Array(screens.enumerated()), id: \.offset) { i, name in
                GeometryReader { geo in
                    Image(name)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { advance() }
                .tag(i)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .background(Theme.Colour.background.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.35), value: index)
        .statusBarHidden(true)
    }

    private func advance() {
        withAnimation(.easeInOut(duration: 0.35)) {
            index = (index >= screens.count - 1) ? homeIndex : index + 1
        }
    }
}

#Preview { DemoFlowView() }
