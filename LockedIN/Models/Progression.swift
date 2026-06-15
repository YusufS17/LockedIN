import Foundation

// MARK: - Progression — Focus XP, LockedIN coins, level (the player economy)
//
// The persisted player economy. Focus XP is earned by genuine, quality participation;
// coins are cosmetic currency (non-withdrawable, never pay-to-win); level is derived
// from total XP via a triangular curve. Pure value type — Codable, exact Int maths.
//
// Level curve: reaching level L needs `100 · L·(L-1)/2` total XP
//   L1 = 0, L2 = 100, L3 = 300, L4 = 600, L5 = 1000, …  (each level costs 100 more)

struct Progression: Codable, Equatable {
    var focusXP: Int = 0
    var coins: Int = 0
    var sessionsCompleted: Int = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0

    /// Total XP required to *reach* level `level` (level ≥ 1).
    static func xpToReach(level: Int) -> Int {
        let l = max(1, level)
        return 100 * (l - 1) * l / 2
    }

    /// Current level derived from total XP.
    var level: Int {
        var l = 1
        while Progression.xpToReach(level: l + 1) <= focusXP { l += 1 }
        return l
    }

    /// XP accumulated within the current level.
    var xpIntoLevel: Int { focusXP - Progression.xpToReach(level: level) }

    /// XP span of the current level (how much to reach the next).
    var xpForThisLevel: Int {
        Progression.xpToReach(level: level + 1) - Progression.xpToReach(level: level)
    }

    /// 0…1 progress toward the next level.
    var levelProgress: Double {
        guard xpForThisLevel > 0 else { return 0 }
        return Double(xpIntoLevel) / Double(xpForThisLevel)
    }
}

// MARK: - RewardOutcome — what a session earned

struct RewardOutcome: Equatable {
    let focusXP: Int
    let coins: Int
    let passed: Bool
    let leveledUp: Bool
    let newLevel: Int
    /// Itemised XP lines for the reveal ("Completed +60", "Clean focus +20", …).
    let breakdown: [Line]

    struct Line: Equatable, Identifiable {
        let id = UUID()
        let label: String
        let xp: Int
    }
}

// MARK: - RewardRules — deterministic, quality-weighted earning
//
// Rewards favour completion, low distraction, break discipline, focus quality, goals,
// and capped streaks — never raw time grinding (VISION economy principle). Pure function
// of the user's scripted result + config; no randomness (SES-04). Coins are a fixed
// fraction of XP so they track effort, not luck.

enum RewardRules {

    /// Coins minted per unit of Focus XP (rounded down). ~1 coin per 8 XP.
    static let coinsPerXPDenominator = 8

    static func evaluate(user: SessionParticipant,
                         config: RoomConfig,
                         streakBefore: Int,
                         levelBefore: Int,
                         xpBefore: Int) -> RewardOutcome {
        let passed = !user.leftEarly && user.distractions <= config.distractionLimit
        var lines: [RewardOutcome.Line] = []

        // Completion is the backbone of the reward.
        lines.append(.init(label: passed ? "Session completed" : "Showed up", xp: passed ? 60 : 15))

        // Focus quality — scales with focused %.
        let focusXP = user.focusPct / 2          // 0…50
        if focusXP > 0 { lines.append(.init(label: "Focus quality \(user.focusPct)%", xp: focusXP)) }

        // Clean-focus bonus — no distractions at all.
        if user.distractions == 0 {
            lines.append(.init(label: "Clean focus — zero distractions", xp: 20))
        } else {
            // Distraction penalty, only over the agreed limit, capped.
            let over = max(0, user.distractions - config.distractionLimit)
            if over > 0 { lines.append(.init(label: "Over distraction limit", xp: -min(30, over * 10))) }
        }

        // Break discipline — finished without bailing.
        if passed { lines.append(.init(label: "Break discipline", xp: 10)) }

        // Streak bonus — capped so it can't dominate (anti-grind).
        let streakAfter = passed ? streakBefore + 1 : 0
        if passed, streakAfter > 1 {
            lines.append(.init(label: "\(streakAfter)-session streak", xp: min(5, streakAfter) * 5))
        }

        let totalXP = max(0, lines.reduce(0) { $0 + $1.xp })
        let coins = totalXP / coinsPerXPDenominator

        let xpAfter = xpBefore + totalXP
        var probe = Progression(focusXP: xpAfter)
        let newLevel = probe.level
        probe.focusXP = xpBefore
        let leveledUp = newLevel > levelBefore

        return RewardOutcome(focusXP: totalXP, coins: coins, passed: passed,
                             leveledUp: leveledUp, newLevel: newLevel, breakdown: lines)
    }
}
