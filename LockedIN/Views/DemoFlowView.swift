import SwiftUI

// MARK: - DemoFlowView — clickable static prototype + ONE real working feature
//
// Walks the approved design (Demo01…Demo10) as full-bleed screens with smooth
// paged slide transitions. Tap anywhere (the on-image button) to advance; swipe works too.
//
// REAL FEATURE: the "Set your lock-in" screen (Demo08) → tap → a genuinely working
// LiveSessionView (set room name + length, live countdown timer with pause/resume/end).
// Finishing the session continues to the "Room complete" results screen.
//
// Narrative order:
//  01 splash → 02 welcome → 03 choose avatar → 04 customise → 05 player ready
//  → 06 first room → 07 home → 08 set your lock-in → [REAL session] → 10 room complete
//  → (loop back to 07 home)

struct DemoFlowView: View {

    private let homeIndex = 6                     // Demo07 (Home)
    private let setLockInIndex = 7               // Demo08 (Set your lock-in)
    private let resultsIndex = 9                 // Demo10 (Room complete)
    private let screens = (1...10).map { String(format: "Demo%02d", $0) }

    @State private var index = 0
    @State private var showSession = false

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
        .fullScreenCover(isPresented: $showSession) {
            LiveSessionView(
                onFinish: {                       // session done → results screen
                    showSession = false
                    withAnimation(.easeInOut(duration: 0.35)) { index = resultsIndex }
                },
                onCancel: { showSession = false } // backed out → stay on Set your lock-in
            )
        }
    }

    private func advance() {
        // The "Set your lock-in" screen launches the real working session.
        if index == setLockInIndex {
            showSession = true
            return
        }
        withAnimation(.easeInOut(duration: 0.35)) {
            index = (index >= screens.count - 1) ? homeIndex : index + 1
        }
    }
}

#Preview { DemoFlowView() }
