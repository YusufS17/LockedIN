import Foundation

enum ForfeitConfig { static let destination = "Fixture" }

@main struct SessionNumericSafetyChecks {
    @MainActor static func main() throws {
        let suite = "LockedIN.numeric-session.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let start = Date(timeIntervalSince1970: 10_000)
        let character = StudyCharacter(id: "fixture", name: "Fixture", spriteAsset: "fixture", fallback: .default)
        let roster = SessionParticipant.makeSolo(userCharacter: character, userName: "Fixture")
        let original = ActiveStudySession(config: .solo, participants: roster, now: start)
        func modified(_ source: ActiveStudySession, _ change: (inout [String: Any]) -> Void) throws -> ActiveStudySession {
            var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(source)) as! [String: Any]
            change(&json)
            return try JSONDecoder().decode(ActiveStudySession.self, from: JSONSerialization.data(withJSONObject: json))
        }
        func preserved(_ session: ActiveStudySession, at now: Date) throws {
            let payload = try JSONEncoder().encode(session)
            defaults.set(payload, forKey: StudySessionStore.persistenceKey)
            let store = StudySessionStore(defaults: defaults, now: now)
            assert(store.current == nil && store.recoveryIssue != nil)
            assert(defaults.data(forKey: StudySessionStore.persistenceKey) == payload)
        }
        let maxInterruptions = try modified(original) { json in
            var people = json["participants"] as! [[String: Any]]
            people[0]["distractions"] = Int.max
            json["participants"] = people
        }
        assert(!maxInterruptions.isValid)
        try preserved(maxInterruptions, at: start.addingTimeInterval(1))
        var saturated = try modified(original) { json in
            var people = json["participants"] as! [[String: Any]]
            people[0]["distractions"] = Int.max - 2
            json["participants"] = people
        }
        saturated.reportInterruption(at: start.addingTimeInterval(1))
        assert(saturated.isValid && saturated.user!.distractions == Int.max - 1)
        saturated.reportInterruption(at: start.addingTimeInterval(2))
        assert(saturated.isValid && saturated.user!.distractions == Int.max - 1)

        var paused = original
        paused.toggleBreak(at: start.addingTimeInterval(10))
        let nearLimit = try modified(paused) { $0["accumulatedBreakSeconds"] = Double(Int.max).nextDown }
        assert(nearLimit.isValid)
        let unsafeNow = start.addingTimeInterval(10 + 2048)
        assert(!nearLimit.isValid(at: unsafeNow))
        assert(nearLimit.breakSeconds(at: unsafeNow) == Int.max)
        var blocked = nearLimit
        blocked.toggleBreak(at: unsafeNow)
        blocked.finish(leaving: true, at: unsafeNow)
        blocked.update(at: unsafeNow)
        assert(blocked == nearLimit)
        try preserved(nearLimit, at: unsafeNow)
        // An accepted machine-bound total stays convertible after a small resume.
        var safeBoundary = try modified(paused) { $0["accumulatedBreakSeconds"] = Double(Int.max).nextDown - 4096 }
        safeBoundary.toggleBreak(at: start.addingTimeInterval(11))
        assert(safeBoundary.isValid && safeBoundary.phase == .focusing)
        safeBoundary.finish(leaving: true, at: start.addingTimeInterval(12))
        assert(safeBoundary.isValid && safeBoundary.phase == .results)

        var revisionBoundary = try modified(original) { $0["checkpointRevision"] = Int.max - 12 }
        revisionBoundary.update(at: start.addingTimeInterval(2000))
        assert(revisionBoundary.isValid && revisionBoundary.phase == .goalCheck)
        assert(revisionBoundary.revision == Int.max - 11)
        let saturatedRevision = revisionBoundary
        revisionBoundary.reviewGoal(.achieved)
        assert(revisionBoundary == saturatedRevision)
        defaults.removeObject(forKey: StudySessionStore.persistenceKey)
        let revisionPayload = try JSONEncoder().encode(revisionBoundary)
        defaults.set(revisionPayload, forKey: StudySessionStore.persistenceKey)
        let revisionRestored = StudySessionStore(defaults: defaults, now: start.addingTimeInterval(2001))
        assert(revisionRestored.current == nil && revisionRestored.recoveryIssue!.contains("revision limit"))
        assert(defaults.data(forKey: StudySessionStore.persistenceKey) == revisionPayload)
        revisionRestored.discardUnreadableSession()
        assert(revisionRestored.current == nil && revisionRestored.recoveryIssue == nil)
        assert(defaults.object(forKey: StudySessionStore.persistenceKey) == nil)
        let almostExhausted = try modified(original) { $0["checkpointRevision"] = Int.max - 12 }
        let boundaryPayload = try JSONEncoder().encode(almostExhausted)
        defaults.set(boundaryPayload, forKey: StudySessionStore.persistenceKey)
        let checkpointStore = StudySessionStore(defaults: defaults, now: start)
        assert(checkpointStore.current == almostExhausted)
        checkpointStore.checkpoint(revisionBoundary)
        assert(checkpointStore.current == nil && checkpointStore.recoveryIssue!.contains("revision limit"))
        assert(defaults.data(forKey: StudySessionStore.persistenceKey) == boundaryPayload)
        checkpointStore.discardUnreadableSession()
        assert(checkpointStore.current == nil && checkpointStore.recoveryIssue == nil)
        defaults.set(boundaryPayload, forKey: StudySessionStore.persistenceKey)
        let autoExpiry = StudySessionStore(defaults: defaults, now: start.addingTimeInterval(2000))
        assert(autoExpiry.current == nil && autoExpiry.recoveryIssue!.contains("revision limit"))
        assert(defaults.data(forKey: StudySessionStore.persistenceKey) == boundaryPayload)
        // Completed receipts at the revision limit remain replayable/acknowledgeable.
        var earlyBoundary = almostExhausted
        earlyBoundary.finish(leaving: true, at: start.addingTimeInterval(10))
        assert(earlyBoundary.isValid && earlyBoundary.phase == .results && !earlyBoundary.hasExhaustedRevisions)
        defaults.set(try JSONEncoder().encode(earlyBoundary), forKey: StudySessionStore.persistenceKey)
        let completed = StudySessionStore(defaults: defaults, now: start.addingTimeInterval(20))
        assert(completed.current == earlyBoundary && completed.recoveryIssue == nil)
        completed.acknowledgeResults(id: earlyBoundary.id)
        assert(completed.current == nil && defaults.object(forKey: StudySessionStore.persistenceKey) == nil)

        let invalidStart = try modified(original) { $0["startedAt"] = -1e30 }
        assert(!invalidStart.isValid)
        try preserved(invalidStart, at: start)
        let invalidDeadline = try modified(original) { json in
            var clock = json["clock"] as! [String: Any]
            clock["deadline"] = -1e30
            json["clock"] = clock
        }
        assert(!invalidDeadline.isValid)
        try preserved(invalidDeadline, at: start)
        for futureSnapshot in [original, paused] {
            let payload = try JSONEncoder().encode(futureSnapshot)
            defaults.set(payload, forKey: StudySessionStore.persistenceKey)
            let skewed = StudySessionStore(defaults: defaults, now: start.addingTimeInterval(-1))
            assert(skewed.recoveryIssue == nil && skewed.current == futureSnapshot)
            assert(skewed.current!.user!.id == roster[0].id)
            var unchanged = skewed.current!
            unchanged.update(at: start.addingTimeInterval(-1))
            unchanged.toggleBreak(at: start.addingTimeInterval(-1))
            unchanged.reportInterruption(at: start.addingTimeInterval(-1))
            unchanged.finish(leaving: true, at: start.addingTimeInterval(-1))
            assert(unchanged == futureSnapshot)
        }
        var safe = original
        safe.reportInterruption(at: Date(timeIntervalSince1970: -1e30))
        safe.toggleBreak(at: start.addingTimeInterval(-1))
        safe.finish(leaving: true, at: Date(timeIntervalSince1970: Double.infinity))
        assert(safe == original)
        let hugeClock = FocusClock(seconds: Int.max, now: start)
        assert(!hugeClock.isValid)
        assert(hugeClock.remaining(at: start) == 0 && hugeClock.focusedSeconds(at: start) == Int.max)

        // Ordinary version-1 fractional history and receipt identity still restore.
        var fractional = original
        fractional.toggleBreak(at: start.addingTimeInterval(10))
        fractional.toggleBreak(at: start.addingTimeInterval(10.75))
        let legacy = try modified(fractional) { $0.removeValue(forKey: "checkpointRevision") }
        defaults.set(try JSONEncoder().encode(legacy), forKey: StudySessionStore.persistenceKey)
        let restored = StudySessionStore(defaults: defaults, now: start.addingTimeInterval(2000))
        assert(restored.recoveryIssue == nil && restored.current!.isValid)
        assert(restored.current!.user!.id == roster[0].id)
        assert(restored.current!.accumulatedBreakSeconds == 0.75)
        assert(restored.current!.user!.recordedBreakSeconds == 0)
        let replay = StudySessionStore(defaults: defaults, now: start.addingTimeInterval(2001))
        assert(replay.current == restored.current && replay.current!.user!.id == roster[0].id)
        print("PASS: interruption saturation, accumulated/live-break numeric bounds, extreme dates, unsafe transition no-ops, raw restore preservation, fractional legacy/replay UUID")
    }
}
