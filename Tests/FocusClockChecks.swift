import Foundation

@main
struct FocusClockChecks {
    static func main() {
        let start = Date(timeIntervalSince1970: 1_000)
        var clock = FocusClock(seconds: 1_500, now: start)
        assert(clock.remaining(at: start) == 1_500)
        // UI suspension must not stretch the countdown.
        assert(clock.remaining(at: start.addingTimeInterval(600)) == 900)
        assert(clock.focusedSeconds(at: start.addingTimeInterval(600)) == 600)
        clock.pause(at: start.addingTimeInterval(600.25))
        assert(clock.remaining(at: start.addingTimeInterval(900)) == 900)
        assert(clock.focusedSeconds(at: start.addingTimeInterval(900)) == 600)
        // Repeated pause/resume calls must not extend the session.
        clock.pause(at: start.addingTimeInterval(1_000))
        clock.resume(at: start.addingTimeInterval(1_200))
        clock.resume(at: start.addingTimeInterval(1_300))
        assert(clock.remaining(at: start.addingTimeInterval(1_300)) == 800)
        assert(clock.remaining(at: start.addingTimeInterval(2_100)) == 0)
        assert(clock.focusedSeconds(at: start.addingTimeInterval(2_100)) == 1_500)
        assert(clock.remaining(at: start.addingTimeInterval(5_000)) == 0)
        let short = FocusClock(seconds: 1, now: start)
        assert(short.remaining(at: start.addingTimeInterval(0.9)) == 1)
        assert(short.remaining(at: start.addingTimeInterval(1)) == 0)
        print("PASS: elapsed time, suspension, breaks, duplicate pause/resume, expiry and rounding")
    }
}
