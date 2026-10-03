import Foundation

// Only the app-root constant is a fixture; session, avatar, catalogue, world,
// persistence, reward and settlement implementations below compile from app source.
enum ForfeitConfig { static let destination = "Test destination" }

final class FailingCommitmentService: CommitmentService {
    var authorisations = 0
    func authoriseHold(participantID: UUID, amountMinorUnits: MinorUnits, contract: CommitmentContract) async throws -> HoldReference {
        authorisations += 1
        throw CocoaError(.fileReadUnknown)
    }
    func settle(holdRef: HoldReference, verdict: SettlementVerdict) async throws -> SettlementRecord {
        throw CocoaError(.fileReadUnknown)
    }
    func walletBalance(participantID: UUID) async -> MinorUnits { 0 }
}

@main
struct StudySessionChecks {
    @MainActor static func main() async throws {
        let suite = "LockedIN.session-checks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let start = Date(timeIntervalSince1970: 10_000)
        var config = RoomConfig.solo
        config.goal = "Read one chapter"
        var appearance = CharacterAppearance.default
        appearance.topStyle = .jacket
        appearance.bottomStyle = .skirt
        appearance.shoeStyle = .boots
        CharacterPersistence.save(appearance: appearance, displayName: "Fixture", defaults: defaults)
        assert(CharacterPersistence.load(defaults: defaults)?.appearance == appearance)
        assert(CharacterPersistence.load(defaults: defaults)?.displayName == "Fixture")
        let character = StudyCharacter(id: "you", name: "Test", spriteAsset: "char_you", fallback: appearance)
        let roster = SessionParticipant.makeSolo(userCharacter: character, userName: "Test")
        let id = roster[0].id
        let store = StudySessionStore(defaults: defaults, now: start)
        assert(store.begin(config: config, participants: roster, now: start))
        assert(!store.begin(config: config, participants: roster, now: start))
        let restored = StudySessionStore(defaults: defaults, now: start.addingTimeInterval(600))
        assert(restored.current!.user!.id == id)
        assert(restored.current!.user!.character.fallback == appearance)
        assert(restored.current!.clock.remaining(at: start.addingTimeInterval(600)) == 900)

        // Decodable checkpoints must retain the frozenSession roster and rules.
        let frozenSession = restored.current!
        var rewritten = try JSONSerialization.jsonObject(with: JSONEncoder().encode(frozenSession)) as! [String: Any]
        var rewrittenRoster = rewritten["participants"] as! [[String: Any]]
        rewrittenRoster[0]["id"] = UUID().uuidString
        rewritten["participants"] = rewrittenRoster
        let changedIdentity = try JSONDecoder().decode(ActiveStudySession.self,
            from: JSONSerialization.data(withJSONObject: rewritten))
        assert(changedIdentity.isValid)
        restored.checkpoint(changedIdentity)
        assert(restored.current == frozenSession)
        rewritten = try JSONSerialization.jsonObject(with: JSONEncoder().encode(frozenSession)) as! [String: Any]
        var rewrittenConfig = rewritten["config"] as! [String: Any]
        rewrittenConfig["goal"] = "Unexpected replacement goal"
        rewritten["config"] = rewrittenConfig
        let changedRules = try JSONDecoder().decode(ActiveStudySession.self,
            from: JSONSerialization.data(withJSONObject: rewritten))
        assert(changedRules.isValid)
        restored.checkpoint(changedRules)
        assert(restored.current == frozenSession)

        var session = restored.current!
        session.reportInterruption(at: start.addingTimeInterval(600))
        session.toggleBreak(at: start.addingTimeInterval(600))
        restored.checkpoint(session)
        let pausedData = defaults.data(forKey: StudySessionStore.persistenceKey)!
        var inconsistent = try JSONSerialization.jsonObject(with: pausedData) as! [String: Any]
        inconsistent["phase"] = "focusing"
        inconsistent.removeValue(forKey: "breakStartedAt")
        let inconsistentData = try JSONSerialization.data(withJSONObject: inconsistent)
        let invalidClock = try JSONDecoder().decode(ActiveStudySession.self, from: inconsistentData)
        assert(!invalidClock.isValid)
        defaults.set(inconsistentData, forKey: StudySessionStore.persistenceKey)
        let rejectedClock = StudySessionStore(defaults: defaults, now: start.addingTimeInterval(5000))
        assert(rejectedClock.current == nil && rejectedClock.recoveryIssue != nil)
        assert(defaults.data(forKey: StudySessionStore.persistenceKey) == inconsistentData)
        defaults.set(pausedData, forKey: StudySessionStore.persistenceKey)
        let paused = StudySessionStore(defaults: defaults, now: start.addingTimeInterval(1200))
        assert(paused.current!.phase == .onBreak && paused.current!.breaksUsed == 1)
        assert(paused.current!.clock.remaining(at: start.addingTimeInterval(1200)) == 900)
        assert(paused.current!.breakSeconds(at: start.addingTimeInterval(1200)) == 600)
        session = paused.current!
        session.reportInterruption(at: start.addingTimeInterval(1200))
        assert(session.user!.distractions == 1) // breaks do not count as interruptions
        session.toggleBreak(at: start.addingTimeInterval(1200))
        session.toggleBreak(at: start.addingTimeInterval(1300))
        assert(session.phase == .focusing && session.breaksUsed == 1) // allowance retained
        paused.checkpoint(session)
        let expired = StudySessionStore(defaults: defaults, now: start.addingTimeInterval(3000))
        assert(expired.current!.phase == .goalCheck && expired.current!.user!.id == id)
        assert(expired.current!.user!.focusedSeconds == 1500 && expired.current!.user!.focusPct == 100)
        assert(expired.current!.user!.recordedBreakSeconds == 600)
        assert(expired.current!.user!.distractions == 1)
        expired.reviewGoal(.partly)
        let results = StudySessionStore(defaults: defaults, now: start.addingTimeInterval(4000))
        assert(results.current!.phase == .results && results.current!.goalReview == .partly)
        results.checkpoint(session) // stale view must not restore a finished timer
        assert(results.current!.phase == .results)
        let frozenResult = results.current!
        var alteredResult = try JSONSerialization.jsonObject(with: JSONEncoder().encode(frozenResult)) as! [String: Any]
        var alteredRoster = alteredResult["participants"] as! [[String: Any]]
        alteredRoster[0]["id"] = UUID().uuidString
        alteredResult["participants"] = alteredRoster
        results.checkpoint(try JSONDecoder().decode(ActiveStudySession.self,
            from: JSONSerialization.data(withJSONObject: alteredResult)))
        assert(results.current == frozenResult)

        let world = WorldStore(state: .seeded, defaults: defaults)
        let reward = world.applySession(user: results.current!.user!, config: config)
        assert(reward.coins >= RoomItemCatalog.cost(for: "plant.cactus"))
        let afterReward = world.state
        let replayWorld = WorldStore(defaults: defaults)
        assert(replayWorld.applySession(user: results.current!.user!, config: config) == reward)
        assert(replayWorld.state == afterReward)
        let beforePurchase = replayWorld.state.progression.coins
        assert(replayWorld.selectRoomItem("plant.cactus") == .purchasedAndPlaced)
        let bought = WorldStore(defaults: defaults)
        assert(bought.state.personalRoom.itemID(for: .plant) == "plant.cactus")
        assert(bought.ownsRoomItem("plant.cactus"))
        assert(bought.state.progression.coins == beforePurchase - RoomItemCatalog.cost(for: "plant.cactus"))
        assert(bought.selectRoomItem("plant.cactus") == .placed)
        assert(bought.state.progression.coins == replayWorld.state.progression.coins)
        results.acknowledgeResults(id: UUID())
        assert(results.current != nil)
        results.acknowledgeResults(id: results.current!.id)
        assert(StudySessionStore(defaults: defaults).current == nil)

        var premature = ActiveStudySession(config: config, participants: roster, now: start)
        premature.finish(leaving: false, at: start.addingTimeInterval(10))
        assert(premature.phase == .focusing)
        var twoBreakConfig = config
        twoBreakConfig.breakAllowance = 2
        var fractional = ActiveStudySession(config: twoBreakConfig, participants: roster, now: start)
        fractional.toggleBreak(at: start.addingTimeInterval(10))
        fractional.toggleBreak(at: start.addingTimeInterval(10.75))
        fractional.toggleBreak(at: start.addingTimeInterval(20))
        fractional.toggleBreak(at: start.addingTimeInterval(20.75))
        assert(fractional.breakSeconds(at: start.addingTimeInterval(30)) == 1)

        var early = ActiveStudySession(config: config, participants: roster, now: start)
        early.toggleBreak(at: start.addingTimeInterval(60))
        early.finish(leaving: true, at: start.addingTimeInterval(180))
        assert(early.phase == .results && early.user!.leftEarly)
        assert(early.user!.focusedSeconds == 60 && early.user!.recordedBreakSeconds == 120)
        let frozen = early
        early.update(at: start.addingTimeInterval(9000))
        early.finish(leaving: false, at: start.addingTimeInterval(9000))
        assert(early == frozen)
        let noReward = RewardRules.evaluate(user: early.user!, config: config, streakBefore: 0, levelBefore: 1, xpBefore: 0)
        assert(noReward.coins == 0 && noReward.focusXP == 0)
        let unfinished = SessionParticipant.makeSolo(userCharacter: character, userName: "New")[0]
        let beforeIncomplete = bought.state
        assert(bought.applySession(user: unfinished, config: config).coins == 0)
        assert(bought.state == beforeIncomplete)

        var demoConfig = config
        demoConfig.quickDemo = true
        var demo = ActiveStudySession(config: demoConfig, participants: roster, now: start)
        demo.update(at: start.addingTimeInterval(20))
        assert(demo.phase == .goalCheck)
        assert(RewardRules.evaluate(user: demo.user!, config: demoConfig, streakBefore: 0, levelBefore: 1, xpBefore: 0).coins == 0)

        // Corrupt/future data is retained until the user explicitly clears it.
        let corrupt = Data("not-json".utf8)
        defaults.set(corrupt, forKey: StudySessionStore.persistenceKey)
        let failed = StudySessionStore(defaults: defaults)
        assert(failed.current == nil && failed.recoveryIssue != nil)
        assert(!failed.begin(config: config, participants: roster))
        assert(defaults.data(forKey: StudySessionStore.persistenceKey) == corrupt)
        failed.discardUnreadableSession()
        assert(failed.recoveryIssue == nil)
        var future = try JSONSerialization.jsonObject(with: JSONEncoder().encode(frozen)) as! [String: Any]
        future["version"] = 999
        let futureData = try JSONSerialization.data(withJSONObject: future)
        defaults.set(futureData, forKey: StudySessionStore.persistenceKey)
        assert(StudySessionStore(defaults: defaults).recoveryIssue != nil)
        assert(defaults.data(forKey: StudySessionStore.persistenceKey) == futureData)

        let service = FailingCommitmentService()
        let freeResult = await SettlementEngine.run(config: config, participants: roster, service: service)
        assert(service.authorisations == 0 && freeResult.totalReturnedPence == 0)
        let failedResult = await SettlementEngine.run(config: .preset, participants: roster, service: service)
        assert(service.authorisations == 1 && failedResult.results[0].settlementFailed)
        assert(failedResult.totalReturnedPence == 0 && failedResult.totalForfeitedPence == 0)
        assert(!ParticipantStudyIntent(subject: "Physics", goal: " ").isValid)
        assert(!ParticipantStudyIntent(subject: " Physics", goal: "Read").isValid)
        assert(!ParticipantStudyIntent(subject: "Physics", goal: "Read\nnotes").isValid)
        // Every supported demo-club size freezes per-person intent and identity.
        for count in 2...8 {
            let clubSuite = "LockedIN.club-checks.\(UUID().uuidString)"
            let clubDefaults = UserDefaults(suiteName: clubSuite)!
            defer { clubDefaults.removePersistentDomain(forName: clubSuite) }
            var clubConfig = RoomConfig.groupRoom
            clubConfig.subject = "Physics"
            clubConfig.goal = "Explain momentum"
            let people = SessionParticipant.makeRoster(userCharacter: character, userName: "Test", config: clubConfig, count: count)
            assert(people.count == count && Set(people.map(\.id)).count == count)
            assert(people.allSatisfy { $0.studyIntent?.isValid == true })
            assert(people[0].studyIntent?.goal == "Explain momentum")
            let club = StudySessionStore(defaults: clubDefaults, now: start)
            assert(club.begin(config: clubConfig, participants: people, now: start))
            var running = club.current!
            running.toggleBreak(at: start.addingTimeInterval(30))
            club.checkpoint(running)
            let saved = StudySessionStore(defaults: clubDefaults, now: start.addingTimeInterval(300))
            assert(saved.current!.participants == running.participants)
            assert(saved.current!.phase == .onBreak)
            var payload = try JSONSerialization.jsonObject(with: JSONEncoder().encode(running)) as! [String: Any]
            var members = payload["participants"] as! [[String: Any]]
            members[1]["studyIntent"] = ["subject": "Changed", "goal": "Changed goal"]
            payload["participants"] = members
            let altered = try JSONDecoder().decode(ActiveStudySession.self, from: JSONSerialization.data(withJSONObject: payload))
            assert(altered.isValid)
            saved.checkpoint(altered)
            assert(saved.current == running)
            // Missing optional intent in pre-upgrade saves must retain original UUIDs.
            for i in members.indices { members[i].removeValue(forKey: "studyIntent") }
            payload["participants"] = members
            let legacy = try JSONDecoder().decode(ActiveStudySession.self, from: JSONSerialization.data(withJSONObject: payload))
            assert(legacy.isValid && legacy.participants.map(\.id) == people.map(\.id))
            assert(legacy.participants.allSatisfy { $0.studyIntent == nil })
            members[0]["studyIntent"] = ["subject": "Physics", "goal": String(repeating: "x", count: 121)]
            payload["participants"] = members
            let invalid = try JSONDecoder().decode(ActiveStudySession.self, from: JSONSerialization.data(withJSONObject: payload))
            assert(!invalid.isValid)
        }
        print("PASS: 2–8 person frozen club rosters/intents, paused restore, legacy intent migration and malformed intent rejection")
        print("PASS: session restoration/UUIDs/custom avatar, breaks/interruptions/expiry, goal review, reward replay, earned item purchase/reload, early exit/demo, incomplete snapshots, corrupt/future recovery and honest settlement failures")
    }
}
