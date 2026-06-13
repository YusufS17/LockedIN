import SwiftUI

// MARK: - RoomFlowView — basic working core loop (MVP)
//
// Commit → stake → session → consequence reveal, in basic functional form.
// Money is Int pence throughout (formatPence / MoneyLabel); deterministic outcome
// (Sam cracks). This is the demo spine in one self-contained flow — Phases 3–6 will
// later replace each stage with the full-fidelity screens.

struct RoomFlowView: View {

    enum Stage { case contract, session, results }

    @Environment(\.dismiss) private var dismiss
    @State private var stage: Stage = .contract

    private let stakePence = 500

    // Deterministic demo roster — You/Maya/Leo pass, Sam cracks.
    private let players: [Player] = [
        Player(name: "You",  passed: true,  distractions: 0, focusPct: 98),
        Player(name: "Maya", passed: true,  distractions: 0, focusPct: 96),
        Player(name: "Leo",  passed: true,  distractions: 1, focusPct: 88),
        Player(name: "Sam",  passed: false, distractions: 4, focusPct: 61)
    ]

    private var returnedPence: Int { players.filter { $0.passed }.count * stakePence }
    private var forfeitedPence: Int { players.filter { !$0.passed }.count * stakePence }

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()
            switch stage {
            case .contract: contractScreen
            case .session:  SessionScreen(playerCount: players.count) { stage = .results }
            case .results:  resultsScreen
            }
        }
    }

    // MARK: - Contract

    private var contractScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("£5 Serious Lock-In")
                        .font(Theme.TypeScale.largeTitle)
                        .foregroundStyle(Theme.Colour.textPrimary)
                    Text("Review the contract, then lock in.")
                        .font(Theme.TypeScale.body)
                        .foregroundStyle(Theme.Colour.textSecondary)
                }

                creamCard {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack {
                            Text("Your stake").font(Theme.TypeScale.headline).foregroundStyle(Theme.Colour.textPrimary)
                            Spacer()
                            MoneyLabel(stakePence)
                        }
                        Divider()
                        Text("Forfeit → ❤️ British Red Cross")
                            .font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                    }
                }

                creamCard {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("KEEPS YOUR £5").font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.moneyGreen)
                        termRow("✓", "Stay focused for 25 min")
                        termRow("✓", "Up to 1 break (5 min)")
                        Divider().padding(.vertical, Theme.Spacing.xs)
                        Text("LOSES YOUR £5").font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.forfeitRed)
                        termRow("✗", "Leave early")
                        termRow("✗", "More than 3 distractions")
                    }
                }

                creamCard {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Room — £20 collectively at stake (£5 each)")
                            .font(Theme.TypeScale.headline).foregroundStyle(Theme.Colour.textPrimary)
                        ForEach(players) { p in
                            HStack {
                                Text(p.name).font(Theme.TypeScale.body).foregroundStyle(Theme.Colour.textPrimary)
                                Spacer()
                                Text("staked £5 ✓").font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.moneyGreen)
                            }
                        }
                    }
                }

                primaryButton("Accept and stake £5 — Lock In") { stage = .session }
                Text("TEST MODE — NO REAL MONEY WILL MOVE")
                    .font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.testBadgeFg)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(Theme.Spacing.lg)
        }
    }

    // MARK: - Results

    private var resultsScreen: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                Text("Session complete")
                    .font(Theme.TypeScale.largeTitle).foregroundStyle(Theme.Colour.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)

                creamCard {
                    VStack(spacing: Theme.Spacing.md) {
                        Text("Room totals").font(Theme.TypeScale.headline).foregroundStyle(Theme.Colour.textPrimary)
                        HStack {
                            VStack(spacing: 2) {
                                Text("Returned").font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                                MoneyLabel(returnedPence)
                            }
                            Spacer()
                            VStack(spacing: 2) {
                                Text("Forfeited").font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                                MoneyLabel(forfeitedPence)
                            }
                        }
                    }
                }

                creamCard {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        titleRow("🏆", "LockedIN Champion", "Maya", "96% focus · 0 distractions")
                        titleRow("💀", "Biggest Culprit", "Sam", "4 distractions · 61% focus · £5 forfeited")
                        titleRow("🥶", "First to Fold", "Sam", "cracked first")
                    }
                }

                creamCard {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        ForEach(players) { p in
                            HStack {
                                Text(p.name).font(Theme.TypeScale.body).foregroundStyle(Theme.Colour.textPrimary)
                                Spacer()
                                Text(p.passed ? "£5 returned" : "£5 forfeited")
                                    .font(Theme.TypeScale.caption)
                                    .foregroundStyle(p.passed ? Theme.Colour.moneyGreen : Theme.Colour.forfeitRed)
                            }
                        }
                    }
                }

                primaryButton("Done") { dismiss() }
            }
            .padding(Theme.Spacing.lg)
        }
    }

    // MARK: - Reusable bits

    private func termRow(_ mark: String, _ text: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text(mark).font(Theme.TypeScale.body)
            Text(text).font(Theme.TypeScale.body).foregroundStyle(Theme.Colour.textPrimary)
        }
    }

    private func titleRow(_ emoji: String, _ title: String, _ who: String, _ stats: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Text(emoji).font(.system(size: 32))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.textSecondary)
                Text(who).font(Theme.TypeScale.headline).foregroundStyle(Theme.Colour.textPrimary)
                Text(stats).font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
            }
            Spacer()
        }
    }

    private func creamCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colour.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
    }

    private func primaryButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Theme.TypeScale.headline)
                .foregroundStyle(Theme.Colour.buttonText)
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
                .background(Theme.Colour.buttonFill)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
        }
    }
}

// MARK: - Player model (demo)

private struct Player: Identifiable {
    let id = UUID()
    let name: String
    let passed: Bool
    let distractions: Int
    let focusPct: Int
}

// MARK: - Session screen (countdown, Swift Concurrency — no Combine)

private struct SessionScreen: View {
    let playerCount: Int
    let onEnd: () -> Void
    @State private var remaining = 12

    private var clock: String { String(format: "%d:%02d", remaining / 60, remaining % 60) }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            Text("Locked in")
                .font(Theme.TypeScale.headline).foregroundStyle(Theme.Colour.textSecondary)
            Text(clock)
                .font(.system(size: 72, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.Colour.textPrimary)
            Text("\(playerCount) studying · 0 distractions")
                .font(Theme.TypeScale.body).foregroundStyle(Theme.Colour.textSecondary)
            Text("Only aggregate signals shown — no names mid-session")
                .font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button("End session early (forfeit £5)") { onEnd() }
                .font(Theme.TypeScale.caption)
                .foregroundStyle(Theme.Colour.forfeitRed)
                .padding(.bottom, Theme.Spacing.xxl)
        }
        .padding(Theme.Spacing.lg)
        .task {
            while remaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                remaining -= 1
            }
            onEnd()
        }
    }
}

#Preview("Room flow") {
    RoomFlowView().environment(AppStore())
}
