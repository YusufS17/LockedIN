import SwiftUI

// MARK: - BrandLockHeader — the gold padlock + "LOCKEDIN" wordmark
//
// The masthead shared by the live room (Demo09) and the reveal (Demo10): a small
// gold padlock chip over the charcoal wordmark, with an optional step pill
// ("4 OF 6") used by the contract/setup flow. Pure Theme tokens, no assets.

struct BrandLockHeader: View {
    var stepText: String? = nil

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Theme.Colour.accent)
                    .frame(width: 34, height: 34)
                    .shadow(color: Theme.Colour.accent.opacity(0.45), radius: 6, y: 2)
                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Theme.Colour.textOnAccent)
            }

            Text("LOCKEDIN")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Theme.Colour.textPrimary)

            if let stepText {
                Text(stepText)
                    .font(Theme.TypeScale.captionBold)
                    .foregroundStyle(Theme.Colour.testBadgeFg)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(Theme.Colour.testBadgeBg)
                    )
            }
        }
    }
}

#Preview {
    ZStack {
        Theme.Colour.background.ignoresSafeArea()
        VStack(spacing: 40) {
            BrandLockHeader()
            BrandLockHeader(stepText: "4 OF 6")
        }
    }
}
