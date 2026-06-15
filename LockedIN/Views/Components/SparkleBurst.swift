import SwiftUI

// MARK: - SparkleBurst — a one-shot radial particle flourish (juice layer)
//
// Code-drawn celebratory burst: N sparkles fly outward from the centre and fade. Purely
// decorative — overlay it behind/around a hero element (trophy, levelled-up building) and
// flip `trigger` to play. Deterministic (angles derive from index — no Date/Random), and
// fully gated on Reduce Motion (renders nothing when motion is reduced).

struct SparkleBurst: View {
    /// Flip to true to play the burst; flipping back to false re-arms it.
    var trigger: Bool
    var count: Int = 10
    var radius: CGFloat = 52
    var colour: Color = Theme.Colour.sparkle
    var symbol: String = "sparkle"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fired = false

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = Double(i) / Double(count) * 2 * .pi
                let r = radius * (i.isMultiple(of: 2) ? 1 : 0.7)   // two-ring spread
                Image(systemName: symbol)
                    .font(.system(size: i.isMultiple(of: 2) ? 12 : 8, weight: .bold))
                    .foregroundStyle(colour)
                    .offset(x: fired ? cos(angle) * r : 0,
                            y: fired ? sin(angle) * r : 0)
                    .opacity(fired ? 0 : 1)
                    .scaleEffect(fired ? 0.3 : 1)
                    .rotationEffect(.degrees(fired ? 90 : 0))
            }
        }
        .allowsHitTesting(false)
        .onAppear { if trigger { play() } }
        .onChange(of: trigger) { _, now in if now { play() } }
    }

    private func play() {
        guard !reduceMotion else { return }
        fired = false
        withAnimation(.easeOut(duration: 0.7).delay(0.01)) { fired = true }
    }
}

#Preview("Sparkle burst") {
    struct Demo: View {
        @State private var go = false
        var body: some View {
            ZStack {
                Theme.Colour.background.ignoresSafeArea()
                ZStack {
                    Circle().fill(Theme.Colour.accent).frame(width: 80, height: 80)
                    SparkleBurst(trigger: go)
                }
                .onTapGesture { go.toggle() }
            }
        }
    }
    return Demo()
}
