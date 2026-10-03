import Foundation

// Minimal input fixtures let the unmodified reward engine run on macOS without
// importing the iOS avatar/UI model graph. App builds validate the real types.
struct RoomConfig {
    var quickDemo = false
    var distractionLimit = 3
    var competitive = false
    var sessionSeconds = 1500
    var breakAllowance = 1
}
struct SessionParticipant {
    var leftEarly = false
    var distractions = 0
    var focusPct = 98
    var focusedSeconds: Int? = 1500
    var recordedBreakCount: Int? = 0
}

@main
struct RewardRulesChecks {
    static func main() {
        func evaluate(_ user: SessionParticipant, _ config: RoomConfig) -> RewardOutcome {
            RewardRules.evaluate(user: user, config: config, streakBefore: 2,
                                 levelBefore: 2, xpBefore: 200)
        }
        let completed = evaluate(SessionParticipant(), RoomConfig())
        assert(completed.passed && completed.coins > 0 && completed.focusXP > 0)
        let left = evaluate(SessionParticipant(leftEarly: true), RoomConfig())
        assert(!left.passed && left.coins == 0 && left.focusXP == 0 && !left.leveledUp)
        assert(left.newLevel == 2)
        let demo = evaluate(SessionParticipant(), RoomConfig(quickDemo: true))
        assert(demo.coins == 0 && demo.focusXP == 0 && !demo.leveledUp)
        print("PASS: completed-session rewards retained; early exit and quick demo mint no XP or coins")
    }
}
