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
        // Divide first; saturate unsupported levels instead of trapping on corrupt input.
        let a = l.isMultiple(of: 2) ? l / 2 : l
        let b = l.isMultiple(of: 2) ? l - 1 : (l - 1) / 2
        let product = a.multipliedReportingOverflow(by: b)
        guard !product.overflow else { return Int.max }
        let xp = product.partialValue.multipliedReportingOverflow(by: 100)
        return xp.overflow ? Int.max : xp.partialValue
    }

    /// Current level derived from total XP.
    var level: Int {
        // Binary search bounds both runtime and arithmetic for enormous decoded XP.
        let target = max(0, focusXP)
        var lower = 1
        var upper = 1
        while Self.xpToReach(level: upper) < target && upper < Int.max / 2 { upper *= 2 }
        while lower < upper {
            let middle = lower + (upper - lower + 1) / 2
            let threshold = Self.xpToReach(level: middle)
            if threshold != Int.max && threshold <= target { lower = middle }
            else { upper = middle - 1 }
        }
        return lower
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

struct RewardOutcome: Codable, Equatable {
    let focusXP: Int
    let coins: Int
    let passed: Bool
    let leveledUp: Bool
    let newLevel: Int
    /// Itemised XP lines for the reveal ("Completed +60", "Clean focus +20", …).
    let breakdown: [Line]

    struct Line: Codable, Equatable, Identifiable {
        var id = UUID()
        let label: String
        let xp: Int
    }
}

// MARK: - RewardRules — deterministic, quality-weighted earning
//
// Rewards use a completed timer and recorded breaks, with capped streaks.
// Timer completion is not a measure of attention or other-app use.

enum RewardRules {

    /// Coins minted per unit of Focus XP (rounded down). ~1 coin per 8 XP.
    static let coinsPerXPDenominator = 8

    static func evaluate(user: SessionParticipant,
                         config: RoomConfig,
                         streakBefore: Int,
                         levelBefore: Int,
                         xpBefore: Int) -> RewardOutcome {
        // Walkthroughs and early exits must not mint completion rewards.
        guard !config.quickDemo, !user.leftEarly, (user.focusedSeconds ?? 0) >= config.sessionSeconds else {
            return RewardOutcome(focusXP: 0, coins: 0, passed: false,
                                 leveledUp: false, newLevel: levelBefore,
                                 breakdown: [.init(label: config.quickDemo ? "Demo — progress not saved" : "Session incomplete — no completion reward", xp: 0)])
        }
        let passed = !config.competitive || user.distractions <= config.distractionLimit
        var lines: [RewardOutcome.Line] = []

        // Completion is the backbone of the reward.
        lines.append(.init(label: passed ? "Session completed" : "Showed up", xp: passed ? 60 : 15))

        // This measures completed timer time, not attention or use of other apps.
        let completion = min(100, max(0, (user.focusedSeconds ?? 0) * 100 / config.sessionSeconds))
        lines.append(.init(label: "Planned timer completed", xp: completion / 2))
        if let breaks = user.recordedBreakCount, breaks <= config.breakAllowance {
            lines.append(.init(label: "Within your break allowance", xp: 10))
        }

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
