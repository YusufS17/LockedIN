import Foundation

@main
enum FriendsChecks {
    static var checks = 0

    static func check(_ condition: @autoclosure () -> Bool, _ label: String) {
        precondition(condition(), label)
        checks += 1
    }

    static func rejects(_ expected: FriendsError, _ label: String, _ body: () throws -> Void) {
        do {
            try body()
            preconditionFailure("Expected rejection: \(label)")
        } catch {
            check((error as? FriendsError) == expected, "\(label): \(error)")
        }
    }

    static func main() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let owner = UUID(), friend = UUID(), stranger = UUID()
        var authority = FriendsAuthority(ownerID: owner)
        let initial = authority.snapshot
        check(initial.isValid && initial.members.count == 1, "One-person lobby is valid")
        rejects(.forbidden, "Private read") { _ = try authority.read(actor: stranger) }
        rejects(.forbidden, "Owner-only invitation") {
            _ = try authority.invite(actor: stranger, recipient: friend, expiresAt: now.addingTimeInterval(60), now: now)
        }
        rejects(.tooFewMembers, "Need two people to start") {
            try authority.start(actor: owner, expectedRevision: 0)
        }
        let invite = try authority.invite(actor: owner, recipient: friend,
                                          expiresAt: now.addingTimeInterval(60), now: now)
        rejects(.invalidInvite, "Recipient-bound admission") {
            try authority.admit(actor: stranger, token: invite.token, now: now, expectedRevision: 0)
        }
        rejects(.invalidInvite, "Expiry boundary is exclusive") {
            try authority.admit(actor: friend, token: invite.token, now: invite.expiresAt, expectedRevision: 0)
        }
        rejects(.staleRevision, "Stale admission") {
            try authority.admit(actor: friend, token: invite.token, now: now, expectedRevision: 1)
        }
        check(authority.snapshot == initial, "Rejected writes do not mutate room")
        try authority.admit(actor: friend, token: invite.token, now: now, expectedRevision: 0)
        let admitted = authority.snapshot
        let friendID = admitted.members.first { $0.accountID == friend }!.participantID
        rejects(.invalidInvite, "Invite is single-use") {
            try authority.admit(actor: friend, token: invite.token, now: now, expectedRevision: 1)
        }
        let revoked = try authority.invite(actor: owner, recipient: stranger,
                                           expiresAt: now.addingTimeInterval(60), now: now)
        rejects(.forbidden, "Only owner revokes invite") {
            try authority.revoke(actor: friend, token: revoked.token)
        }
        try authority.revoke(actor: owner, token: revoked.token)
        rejects(.invalidInvite, "Revoked invite") {
            try authority.admit(actor: stranger, token: revoked.token, now: now, expectedRevision: 1)
        }
        // Fill the remaining slots; the authority serializes admission checks.
        for _ in 0..<6 {
            let person = UUID()
            let entry = try authority.invite(actor: owner, recipient: person,
                                             expiresAt: now.addingTimeInterval(60), now: now)
            try authority.admit(actor: person, token: entry.token, now: now,
                                expectedRevision: authority.snapshot.revision)
        }
        check(authority.snapshot.members.count == 8, "Eight-member upper bound")
        let ninth = try authority.invite(actor: owner, recipient: stranger,
                                         expiresAt: now.addingTimeInterval(60), now: now)
        rejects(.full, "Ninth member rejected") {
            try authority.admit(actor: stranger, token: ninth.token, now: now,
                                expectedRevision: authority.snapshot.revision)
        }
        rejects(.forbidden, "Member cannot start room") {
            try authority.start(actor: friend, expectedRevision: authority.snapshot.revision)
        }
        try authority.start(actor: owner, expectedRevision: authority.snapshot.revision)
        let started = authority.snapshot
        rejects(.invalidPhase, "Roster freezes on start") {
            try authority.admit(actor: stranger, token: ninth.token, now: now,
                                expectedRevision: authority.snapshot.revision)
        }
        rejects(.forbidden, "Outsider cannot send presence") {
            try authority.setPresence(actor: stranger, presence: .away, expectedRevision: started.revision)
        }
        rejects(.invalidPhase, "Client presence cannot finish session") {
            try authority.setPresence(actor: friend, presence: .finished, expectedRevision: started.revision)
        }
        try authority.setPresence(actor: friend, presence: .onBreak, expectedRevision: started.revision)
        rejects(.staleRevision, "Concurrent command loses revision race") {
            try authority.setPresence(actor: owner, presence: .away, expectedRevision: started.revision)
        }
        let onBreak = authority.snapshot
        try authority.setPresence(actor: friend, presence: .onBreak, expectedRevision: onBreak.revision)
        check(authority.snapshot == onBreak, "Identical presence is a no-op")
        check(onBreak.members.first { $0.accountID == owner }?.presence == .focusing,
              "Member only changes own presence")

        var replica = FriendsReplica(sessionID: initial.sessionID, accountID: friend)
        rejects(.forbidden, "Unadmitted account cannot consume private snapshot") {
            try replica.receive(initial)
        }
        check(tryReceive(&replica, admitted), "First admitted snapshot")
        check(tryReceive(&replica, onBreak), "Full snapshots can skip revisions")
        replica.disconnect()
        check(!tryReceive(&replica, started) && !replica.connected,
              "Old delayed snapshot neither regresses state nor confirms reconnect")
        check(!tryReceive(&replica, onBreak) && replica.connected, "Equal snapshot confirms reconnect")
        let conflict = FriendsSnapshot(sessionID: onBreak.sessionID, ownerID: owner, revision: onBreak.revision,
                                       phase: started.phase, members: started.members)
        rejects(.conflictingRevision, "Same revision with different content") { try replica.receive(conflict) }
        let wrong = FriendsSnapshot(sessionID: UUID(), ownerID: owner, revision: 100,
                                    phase: onBreak.phase, members: onBreak.members)
        rejects(.wrongSession, "Cross-session isolation") { try replica.receive(wrong) }
        var changedMembers = onBreak.members
        let index = changedMembers.firstIndex { $0.accountID == friend }!
        changedMembers[index] = FriendMember(accountID: friend, participantID: UUID(), presence: .onBreak)
        let changedIdentity = FriendsSnapshot(sessionID: onBreak.sessionID, ownerID: owner,
                                              revision: onBreak.revision + 1, phase: .studying, members: changedMembers)
        rejects(.identityChanged, "Reward identity cannot rotate on reconnect") { try replica.receive(changedIdentity) }
        let duplicateMember = FriendsSnapshot(sessionID: onBreak.sessionID, ownerID: owner,
                                              revision: onBreak.revision + 1, phase: .studying,
                                              members: [onBreak.members[0], onBreak.members[0]])
        rejects(.invalidSnapshot, "Duplicate roster rejected") { try replica.receive(duplicateMember) }
        let regressed = FriendsSnapshot(sessionID: admitted.sessionID, ownerID: owner,
                                        revision: onBreak.revision + 1, phase: .lobby,
                                        members: onBreak.members.map {
                                            FriendMember(accountID: $0.accountID,
                                                         participantID: $0.participantID, presence: .ready)
                                        })
        rejects(.invalidSnapshot, "Higher revision cannot reopen lobby") { try replica.receive(regressed) }
        check(replica.snapshot == onBreak, "Rejected snapshots preserve last known state")
        try authority.finish(actor: owner, expectedRevision: authority.snapshot.revision)
        let finished = authority.snapshot
        check(tryReceive(&replica, finished), "Terminal state accepted")
        rejects(.invalidPhase, "Terminal session cannot resume") {
            try authority.setPresence(actor: friend, presence: .focusing, expectedRevision: finished.revision)
        }
        let encoded = try JSONEncoder().encode(finished)
        let restored = try JSONDecoder().decode(FriendsSnapshot.self, from: encoded)
        var relaunched = FriendsReplica(sessionID: finished.sessionID, accountID: friend)
        try relaunched.restoreCachedSnapshot(restored)
        check(!relaunched.connected, "Restoring cached data does not imply live connectivity")
        check(restored == finished, "Snapshot round trip")
        check(relaunched.snapshot?.members.first { $0.accountID == friend }?.participantID == friendID,
              "Admission, focus, completion and restoration retain receipt UUID")
        // An allowlist check prevents accidental addition of sensitive wire fields.
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        check(Set(json.keys) == Set(["sessionID", "ownerID", "revision", "phase", "members"]),
              "Snapshot wire-field allowlist")
        let memberJSON = (json["members"] as! [[String: Any]])[0]
        check(Set(memberJSON.keys) == Set(["accountID", "participantID", "presence"]),
              "Presence excludes app/site/contact/message/interruption detail")
        try connectionChecks(now: now)
        print("PASS: \(checks) private-friends prototype checks (in-memory fixtures; no networking or app integration)")
    }

    static func connectionChecks(now: Date) throws {
        let owner = UUID(), friend = UUID(), outsider = UUID()
        var server = FriendsAuthority(ownerID: owner)
        let subject = SharedStudyIntent(subject: "Biology", goal: "Review photosynthesis")
        try server.setSharedIntent(actor: owner, intent: subject, expectedRevision: 0)
        let invited = try server.invite(actor: owner, recipient: friend, expiresAt: now.addingTimeInterval(60), now: now)
        rejects(.forbidden, "Invite recipient cannot read until admitted") { _ = try server.readEnvelope(actor: friend) }
        rejects(.forbidden, "Outsider cannot publish intent") {
            try server.setSharedIntent(actor: outsider, intent: subject, expectedRevision: server.snapshot.revision)
        }
        try server.admit(actor: friend, token: invited.token, now: now, expectedRevision: server.snapshot.revision)
        let lobby = server.snapshot
        let friendID = lobby.members.first { $0.accountID == friend }!.participantID
        for bad in [SharedStudyIntent(subject: "Math", goal: ""), SharedStudyIntent(subject: "Math", goal: "   "),
                    SharedStudyIntent(subject: "", goal: "Study"), SharedStudyIntent(subject: String(repeating: "a", count: 41), goal: "Study"),
                    SharedStudyIntent(subject: "Math", goal: String(repeating: "a", count: 121)),
                    SharedStudyIntent(subject: " Math", goal: "Study"), SharedStudyIntent(subject: "Math", goal: "x\ny")] {
            rejects(.invalidIntent, "Invalid shared text") {
                try server.setSharedIntent(actor: friend, intent: bad, expectedRevision: server.snapshot.revision)
            }
        }
        check(server.snapshot == lobby, "Rejected intent leaves room unchanged")
        let maximum = SharedStudyIntent(subject: String(repeating: "é", count: 40), goal: String(repeating: "🙂", count: 120))
        try server.setSharedIntent(actor: friend, intent: maximum, expectedRevision: server.snapshot.revision)
        check(server.snapshot.members.first { $0.accountID == owner }?.sharedIntent == subject, "Member changes only own shared text")
        try server.setSharedIntent(actor: friend, intent: nil, expectedRevision: server.snapshot.revision)
        check(server.snapshot.members.first { $0.accountID == friend }?.sharedIntent == nil, "Sharing can be withdrawn in lobby")
        let ownerEnvelope = try server.readEnvelope(actor: owner)
        let friendEnvelope = try server.readEnvelope(actor: friend)
        check(ownerEnvelope.snapshot == friendEnvelope.snapshot && ownerEnvelope.recipientID != friendEnvelope.recipientID,
              "Both admitted clients see same explicitly shared content with scoped envelopes")
        var a = FriendsConnection(sessionID: lobby.sessionID, accountID: owner)
        var b = FriendsConnection(sessionID: lobby.sessionID, accountID: friend)
        rejects(.wrongRecipient, "Cross-account cached envelope rejected") { try b.restoreCachedSnapshot(ownerEnvelope) }
        try b.restoreCachedSnapshot(friendEnvelope)
        rejects(.disconnected, "Cached display cannot send commands") { _ = try b.commandRevision() }
        let a1 = a.beginReconnect(), b1 = b.beginReconnect()
        check(!must { try b.receiveStream(friendEnvelope, generation: b1) }, "Stream before authorised read ignored")
        check(!b.controlsEnabled, "Opening connection does not enable controls")
        _ = try a.receiveFreshRead(ownerEnvelope, generation: a1)
        _ = try b.receiveFreshRead(friendEnvelope, generation: b1)
        check(a.controlsEnabled && b.controlsEnabled, "Fresh membership checked reads enable both clients")
        try server.start(actor: owner, expectedRevision: try a.commandRevision())
        let started = server.snapshot
        rejects(.invalidPhase, "Shared intent frozen on start") {
            try server.setSharedIntent(actor: owner, intent: nil, expectedRevision: started.revision)
        }
        try server.setPresence(actor: friend, presence: .onBreak, expectedRevision: started.revision)
        let onBreak = try server.readEnvelope(actor: friend)
        _ = try b.receiveStream(onBreak, generation: b1)
        check(b.snapshot == server.snapshot, "Dropped start frame recovered by full later snapshot")
        check(!must { try b.receiveStream(FriendsEnvelope(recipientID: friend, snapshot: started), generation: b1) },
              "Reordered stream does not regress break")
        _ = try a.receiveStream(try server.readEnvelope(actor: owner), generation: a1)
        check(a.snapshot == b.snapshot, "Two clients converge despite different deliveries")
        b.disconnect(generation: b1)
        check(b.snapshot == onBreak.snapshot && !b.controlsEnabled, "Network loss retains display but disables controls")
        check(!must { try b.receiveStream(onBreak, generation: b1) }, "Closed subscription callbacks ignored")
        let b2 = b.beginReconnect()
        check(!must { try b.receiveFreshRead(onBreak, generation: b1) }, "Old fresh-read callback cannot confirm new connection")
        b.accessDenied(generation: b1)
        b.disconnect(generation: b1)
        check(b.generation == b2 && b.snapshot != nil, "Old denial/disconnect cannot tear down new connection")
        _ = try b.receiveFreshRead(FriendsEnvelope(recipientID: friend, snapshot: started), generation: b2)
        check(!b.controlsEnabled, "Fresh read older than cache remains disabled")
        _ = try b.receiveFreshRead(onBreak, generation: b2)
        check(b.controlsEnabled, "Identical current read authorises reconnect without revision increment")
        check(b.snapshot?.members.first { $0.accountID == friend }?.participantID == friendID,
              "Reconnect retains app reward receipt participant UUID")
        var changed = onBreak.snapshot.members
        changed[0].sharedIntent = SharedStudyIntent(subject: "Changed", goal: "Changed goal")
        let illegal = FriendsEnvelope(recipientID: friend, snapshot: FriendsSnapshot(sessionID: lobby.sessionID,
            ownerID: owner, revision: onBreak.snapshot.revision + 1, phase: .studying, members: changed))
        rejects(.invalidSnapshot, "Higher revision cannot rewrite frozen shared intent") { _ = try b.receiveStream(illegal, generation: b2) }
        check(!b.controlsEnabled && b.generation == nil && b.snapshot == onBreak.snapshot, "Invalid stream closes generation without corrupting cache")
        check(!must { try b.receiveFreshRead(onBreak, generation: b2) }, "Invalidated generation cannot recover from queued read")
        let conflictToken = b.beginReconnect()
        _ = try b.receiveFreshRead(onBreak, generation: conflictToken)
        var conflictingMembers = onBreak.snapshot.members
        conflictingMembers[0].presence = .away
        let conflicting = FriendsEnvelope(recipientID: friend, snapshot: FriendsSnapshot(sessionID: lobby.sessionID,
            ownerID: owner, revision: onBreak.snapshot.revision, phase: .studying, members: conflictingMembers))
        rejects(.conflictingRevision, "Contradictory stream closes connection") { _ = try b.receiveStream(conflicting, generation: conflictToken) }
        check(!b.controlsEnabled && b.snapshot == onBreak.snapshot, "Conflict retains last valid display and disables commands")
        rejects(.disconnected, "Conflict cannot send command revision") { _ = try b.commandRevision() }
        let invalidToken = b.beginReconnect()
        changed[0].sharedIntent = SharedStudyIntent(subject: "", goal: "")
        let invalid = FriendsEnvelope(recipientID: friend, snapshot: FriendsSnapshot(sessionID: lobby.sessionID,
            ownerID: owner, revision: onBreak.snapshot.revision + 1, phase: .studying, members: changed))
        rejects(.invalidSnapshot, "Decoded malformed shared text rejected") { _ = try b.receiveFreshRead(invalid, generation: invalidToken) }
        let b3 = b.beginReconnect()
        rejects(.wrongRecipient, "Wrong recipient reconnect read rejected") { _ = try b.receiveFreshRead(ownerEnvelope, generation: b3) }
        check(!b.controlsEnabled, "Wrong recipient never authorises controls")
        let b4 = b.beginReconnect()
        _ = try b.receiveFreshRead(onBreak, generation: b4)
        b.accessDenied(generation: b4)
        check(b.snapshot == nil && !b.controlsEnabled && b.generation == nil, "Current permission denial clears private cache")
        check(!must { try b.receiveStream(onBreak, generation: b4) }, "Queued revoked callback cannot restore private cache")
        var cacheCheck = FriendsConnection(sessionID: lobby.sessionID, accountID: friend)
        try cacheCheck.restoreCachedSnapshot(onBreak)
        rejects(.invalidSnapshot, "Cache hydration is startup only") { try cacheCheck.restoreCachedSnapshot(onBreak) }
        _ = cacheCheck.beginReconnect()
        rejects(.invalidPhase, "Cache cannot replace reconnect response") { try cacheCheck.restoreCachedSnapshot(onBreak) }
        let data = try JSONEncoder().encode(ownerEnvelope)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        check(Set(json.keys) == Set(["recipientID", "snapshot"]), "Envelope wire allowlist")
        let members = (json["snapshot"] as! [String: Any])["members"] as! [[String: Any]]
        let shared = members.first { $0["sharedIntent"] != nil }!["sharedIntent"] as! [String: Any]
        check(Set(shared.keys) == Set(["subject", "goal"]), "Only elected subject/goal shared; no private review field")
        var relaunched = FriendsConnection(sessionID: lobby.sessionID, accountID: friend)
        try relaunched.restoreCachedSnapshot(try JSONDecoder().decode(FriendsEnvelope.self, from: JSONEncoder().encode(onBreak)))
        check(relaunched.snapshot == onBreak.snapshot && !relaunched.controlsEnabled, "Account-scoped cache round trip remains disconnected")
    }

    static func must<T>(_ body: () throws -> T) -> T {
        do { return try body() } catch { preconditionFailure("Unexpected error: \(error)") }
    }

    static func tryReceive(_ replica: inout FriendsReplica, _ snapshot: FriendsSnapshot) -> Bool {
        do { return try replica.receive(snapshot) }
        catch { preconditionFailure("Unexpected replica error: \(error)") }
    }
}
