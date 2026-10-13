import Foundation

enum ForfeitConfig { static let destination = "Fixture" }

@main struct SessionValidationChecks {
    @MainActor static func main() throws {
        let suite = "LockedIN.session-validation.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let start = Date(timeIntervalSince1970: 10_000)
        let config = RoomConfig.solo
        let character = StudyCharacter(id: "fixture", name: "Fixture", spriteAsset: "fixture", fallback: .default)
        let roster = SessionParticipant.makeSolo(userCharacter: character, userName: "Fixture")
        let store = StudySessionStore(defaults: defaults, now: start)
        assert(store.begin(config: config, participants: roster, now: start))
        let stale = store.current!
        var live = stale
        live.reportInterruption(at: start.addingTimeInterval(10))
        store.checkpoint(live)
        store.checkpoint(stale)
        assert(store.current == live)
        var competing = stale
        competing.toggleBreak(at: start.addingTimeInterval(15))
        store.checkpoint(competing)
        assert(store.current == live) // an independently edited equal-revision snapshot is stale
        live.toggleBreak(at: start.addingTimeInterval(20))
        store.checkpoint(live)
        live.toggleBreak(at: start.addingTimeInterval(30))
        store.checkpoint(live)
        live.update(at: start.addingTimeInterval(2000))
        assert(live.isValid && live.phase == .goalCheck)
        store.checkpoint(live)
        store.reviewGoal(.achieved)
        let result = store.current!
        assert(result.isValid && result.user!.id == roster[0].id)
        func modified(_ change: (inout [String: Any]) -> Void) throws -> ActiveStudySession {
            var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(result)) as! [String: Any]
            change(&json)
            return try JSONDecoder().decode(ActiveStudySession.self, from: JSONSerialization.data(withJSONObject: json))
        }
        let legacy = try modified { $0.removeValue(forKey: "checkpointRevision") }
        assert(legacy.isValid && legacy.revision == 0 && legacy.user!.id == roster[0].id)
        for key in ["focusPct", "focusedSeconds", "recordedBreakCount", "recordedBreakSeconds"] {
            let invalid = try modified { json in
                var people = json["participants"] as! [[String: Any]]
                people[0][key] = -1
                json["participants"] = people
            }
            assert(!invalid.isValid)
            let payload = try JSONEncoder().encode(invalid)
            defaults.set(payload, forKey: StudySessionStore.persistenceKey)
            let recovered = StudySessionStore(defaults: defaults, now: start.addingTimeInterval(3000))
            assert(recovered.current == nil && recovered.recoveryIssue != nil)
            assert(defaults.data(forKey: StudySessionStore.persistenceKey) == payload)
        }
        let missingReview = try modified { $0.removeValue(forKey: "goalReview") }
        assert(!missingReview.isValid)
        let staked = try modified { json in
            var config = json["config"] as! [String: Any]
            config["stakePence"] = 500
            json["config"] = config
        }
        assert(!staked.isValid)
        store.acknowledgeResults(id: result.id)
        assert(store.begin(config: config, participants: roster, now: start))
        var fractional = store.current!
        fractional.toggleBreak(at: start.addingTimeInterval(1))
        store.checkpoint(fractional)
        fractional.toggleBreak(at: start.addingTimeInterval(1.7))
        store.checkpoint(fractional)
        fractional.update(at: start.addingTimeInterval(2000))
        store.checkpoint(fractional)
        assert(store.current?.phase == .goalCheck)
        assert(store.current!.accumulatedBreakSeconds > 0.6 && store.current!.user!.recordedBreakSeconds == 0)
        defaults.set("unreadable session value", forKey: StudySessionStore.persistenceKey)
        let wrongType = StudySessionStore(defaults: defaults, now: start)
        assert(wrongType.current == nil && wrongType.recoveryIssue != nil)
        assert(!wrongType.begin(config: config, participants: roster, now: start))
        assert(defaults.string(forKey: StudySessionStore.persistenceKey) == "unreadable session value")
        print("PASS: stale/equal-revision snapshots, legitimate transitions, legacy identity, contradictory outcomes and preserved rejected payloads")
    }
}
