import Foundation

// Only the app-root constant is a fixture; both service implementations are real.
enum ForfeitConfig { static let destination = "British Red Cross" }

@main
struct ServiceBoundaryChecks {
    static func main() async throws {
        try await checkHolds()
        await checkMonitoringReplacement()
        print("PASS: authorised hold identity, rejected forgery, balance conservation, replay, monitor replacement and stop isolation (disposable fixtures only)")
    }

    static func checkHolds() async throws {
        let service = MockCommitmentService()
        let owner = UUID(), stranger = UUID()
        let contract = CommitmentContract(roomName: "Fixture", durationSeconds: 60,
            stakeMinorUnits: 500, maxDistractionSeconds: 3, maxBreaks: 1)!.frozen()
        let hold = try await service.authoriseHold(participantID: owner, amountMinorUnits: 500, contract: contract)
        for forged in [
            HoldReference(id: hold.id, participantID: owner, amountMinorUnits: 1_500),
            HoldReference(id: hold.id, participantID: stranger, amountMinorUnits: 500),
            HoldReference(id: hold.id, participantID: owner, amountMinorUnits: -500)
        ] {
            do {
                _ = try await service.settle(holdRef: forged, verdict: .passed)
                fatalError("A forged reference must not consume a hold or change balances")
            } catch CommitmentServiceError.invalidHoldReference(let id) {
                assert(id == hold.id)
            }
            let ownerBalance = await service.walletBalance(participantID: owner)
            let strangerBalance = await service.walletBalance(participantID: stranger)
            assert(ownerBalance == 1_500 && strangerBalance == 2_000)
        }
        let returned = try await service.settle(holdRef: hold, verdict: .passed)
        assert(returned.holdRef == hold && returned.returnedMinorUnits == 500 && returned.forfeitedMinorUnits == 0)
        let balance = await service.walletBalance(participantID: owner)
        assert(balance == 2_000)
        do {
            _ = try await service.settle(holdRef: hold, verdict: .passed)
            fatalError("A settled hold must not pay again")
        } catch CommitmentServiceError.holdNotFound(let id) { assert(id == hold.id) }
        let failedHold = try await service.authoriseHold(participantID: owner, amountMinorUnits: 500, contract: contract)
        let forfeited = try await service.settle(holdRef: failedHold, verdict: .failed)
        assert(forfeited.returnedMinorUnits == 0 && forfeited.forfeitedMinorUnits == 500)
        let finalBalance = await service.walletBalance(participantID: owner)
        assert(finalBalance == 1_500)
    }

    static func checkMonitoringReplacement() async {
        let person = UUID(), other = UUID()
        let event = FocusEvent.breakStarted(participantID: person, at: Date(timeIntervalSince1970: 1_000))
        let otherEvent = FocusEvent.breakEnded(participantID: other, at: Date(timeIntervalSince1970: 1_001))
        let adapter = MockFocusControlAdapter(scripts: [
            person: [ScriptedFocusEvent(offsetSeconds: 0.01, event: event)],
            other: [ScriptedFocusEvent(offsetSeconds: 0.01, event: otherEvent)]
        ])
        // Finish/cancel of a displaced stream must never finish its replacement.
        for _ in 0..<40 {
            let displaced = adapter.startMonitoring(participantID: person)
            let oldConsumer = Task { for await _ in displaced {} }
            let replacement = adapter.startMonitoring(participantID: person)
            oldConsumer.cancel()
            var received: [FocusEvent] = []
            for await value in replacement { received.append(value) }
            await oldConsumer.value
            assert(received == [event], "Old termination cancelled a replacement monitor")
        }
        let stopped = adapter.startMonitoring(participantID: person)
        let independent = adapter.startMonitoring(participantID: other)
        adapter.stopMonitoring(participantID: person)
        adapter.stopMonitoring(participantID: person)
        var stoppedEvents: [FocusEvent] = []
        for await value in stopped { stoppedEvents.append(value) }
        assert(stoppedEvents.isEmpty)
        var otherEvents: [FocusEvent] = []
        for await value in independent { otherEvents.append(value) }
        assert(otherEvents == [otherEvent], "Stopping one participant affected another")
        let empty = MockFocusControlAdapter().startMonitoring(participantID: UUID())
        for await _ in empty { fatalError("Empty script emitted an event") }
    }
}
