import Foundation

// In-memory contract fixture only. Not an authentication or networking implementation.
enum FriendsError: Error, Equatable {
    case forbidden, invalidInvite, full, staleRevision, invalidPhase, tooFewMembers
    case invalidSnapshot, wrongSession, conflictingRevision, identityChanged
    case invalidIntent, disconnected, wrongRecipient
}

enum FriendsPhase: String, Codable { case lobby, studying, finished }
enum AggregatePresence: String, Codable { case ready, focusing, onBreak, away, finished }

/// Only text the person explicitly elected to share belongs in this wire type.
/// Private planning text and post-session review are never accepted by the authority.
struct SharedStudyIntent: Codable, Equatable {
    let subject: String
    let goal: String

    var isValid: Bool {
        !subject.isEmpty && !goal.isEmpty && subject.count <= 40 && goal.count <= 120 &&
        [subject, goal].allSatisfy {
            $0 == $0.trimmingCharacters(in: .whitespacesAndNewlines) &&
            $0.unicodeScalars.allSatisfy { !CharacterSet.controlCharacters.contains($0) }
        }
    }
}

struct FriendMember: Codable, Equatable {
    let accountID: UUID
    // Created once by the authority per session. Must become SessionParticipant.id on integration.
    let participantID: UUID
    var presence: AggregatePresence
    var sharedIntent: SharedStudyIntent? = nil
}

struct FriendsSnapshot: Codable, Equatable {
    let sessionID: UUID
    let ownerID: UUID
    let revision: Int
    let phase: FriendsPhase
    let members: [FriendMember]

    var isValid: Bool {
        revision >= 0 && (1...8).contains(members.count) &&
        (phase == .lobby || members.count >= 2) &&
        Set(members.map(\.accountID)).count == members.count &&
        Set(members.map(\.participantID)).count == members.count &&
        members.contains { $0.accountID == ownerID } &&
        members.allSatisfy {
            guard $0.sharedIntent?.isValid != false else { return false }
            switch phase {
            case .lobby: return $0.presence == .ready
            case .studying: return [.focusing, .onBreak, .away].contains($0.presence)
            case .finished: return $0.presence == .finished
            }
        }
    }
}

struct FriendInvite {
    let token: UUID // Fixture convenience; production must use a cryptographic bearer secret.
    let recipientID: UUID
    let expiresAt: Date
}

/// A value-type reducer standing in for a serialized server transaction.
/// `actor` must come from verified auth middleware in production, never a client body.
struct FriendsAuthority {
    private(set) var snapshot: FriendsSnapshot
    private var invites: [UUID: FriendInvite] = [:]

    init(ownerID: UUID, sessionID: UUID = UUID()) {
        snapshot = FriendsSnapshot(sessionID: sessionID, ownerID: ownerID, revision: 0,
                                   phase: .lobby, members: [FriendMember(accountID: ownerID,
                                       participantID: UUID(), presence: .ready)])
    }

    func read(actor: UUID) throws -> FriendsSnapshot {
        guard snapshot.members.contains(where: { $0.accountID == actor }) else {
            throw FriendsError.forbidden
        }
        return snapshot
    }

    mutating func invite(actor: UUID, recipient: UUID, expiresAt: Date, now: Date) throws -> FriendInvite {
        guard actor == snapshot.ownerID else { throw FriendsError.forbidden }
        guard snapshot.phase == .lobby else { throw FriendsError.invalidPhase }
        guard expiresAt > now else { throw FriendsError.invalidInvite }
        let invite = FriendInvite(token: UUID(), recipientID: recipient, expiresAt: expiresAt)
        invites[invite.token] = invite
        return invite
    }

    mutating func revoke(actor: UUID, token: UUID) throws {
        guard actor == snapshot.ownerID else { throw FriendsError.forbidden }
        invites.removeValue(forKey: token)
    }

    mutating func admit(actor: UUID, token: UUID, now: Date, expectedRevision: Int) throws {
        try checkRevision(expectedRevision)
        guard snapshot.phase == .lobby else { throw FriendsError.invalidPhase }
        guard let invite = invites[token], invite.recipientID == actor, now < invite.expiresAt else {
            throw FriendsError.invalidInvite
        }
        guard !snapshot.members.contains(where: { $0.accountID == actor }) else {
            throw FriendsError.forbidden
        }
        guard snapshot.members.count < 8 else { throw FriendsError.full }
        let member = FriendMember(accountID: actor, participantID: UUID(), presence: .ready)
        invites.removeValue(forKey: token)
        commit(phase: .lobby, members: snapshot.members + [member])
    }

    mutating func start(actor: UUID, expectedRevision: Int) throws {
        guard actor == snapshot.ownerID else { throw FriendsError.forbidden }
        try checkRevision(expectedRevision)
        guard snapshot.phase == .lobby else { throw FriendsError.invalidPhase }
        guard snapshot.members.count >= 2 else { throw FriendsError.tooFewMembers }
        invites.removeAll()
        commit(phase: .studying, members: snapshot.members.map {
            FriendMember(accountID: $0.accountID, participantID: $0.participantID, presence: .focusing, sharedIntent: $0.sharedIntent)
        })
    }

    /// `nil` withdraws previously shared intent while the lobby is open.
    mutating func setSharedIntent(actor: UUID, intent: SharedStudyIntent?, expectedRevision: Int) throws {
        guard let index = snapshot.members.firstIndex(where: { $0.accountID == actor }) else {
            throw FriendsError.forbidden
        }
        try checkRevision(expectedRevision)
        guard snapshot.phase == .lobby else { throw FriendsError.invalidPhase }
        guard intent?.isValid != false else { throw FriendsError.invalidIntent }
        var members = snapshot.members
        guard members[index].sharedIntent != intent else { return }
        members[index].sharedIntent = intent
        commit(phase: .lobby, members: members)
    }

    func readEnvelope(actor: UUID) throws -> FriendsEnvelope {
        FriendsEnvelope(recipientID: actor, snapshot: try read(actor: actor))
    }

    mutating func setPresence(actor: UUID, presence: AggregatePresence, expectedRevision: Int) throws {
        guard let index = snapshot.members.firstIndex(where: { $0.accountID == actor }) else {
            throw FriendsError.forbidden
        }
        try checkRevision(expectedRevision)
        guard snapshot.phase == .studying, [.focusing, .onBreak, .away].contains(presence) else {
            throw FriendsError.invalidPhase
        }
        var members = snapshot.members
        guard members[index].presence != presence else { return }
        members[index].presence = presence
        commit(phase: .studying, members: members)
    }

    // Fixture-only terminal transition: does not establish timer completion or reward eligibility.
    mutating func finish(actor: UUID, expectedRevision: Int) throws {
        guard actor == snapshot.ownerID else { throw FriendsError.forbidden }
        try checkRevision(expectedRevision)
        guard snapshot.phase == .studying else { throw FriendsError.invalidPhase }
        commit(phase: .finished, members: snapshot.members.map {
            FriendMember(accountID: $0.accountID, participantID: $0.participantID, presence: .finished, sharedIntent: $0.sharedIntent)
        })
    }

    private func checkRevision(_ expected: Int) throws {
        guard expected == snapshot.revision else { throw FriendsError.staleRevision }
    }

    private mutating func commit(phase: FriendsPhase, members: [FriendMember]) {
        snapshot = FriendsSnapshot(sessionID: snapshot.sessionID, ownerID: snapshot.ownerID,
                                   revision: snapshot.revision + 1, phase: phase, members: members)
    }
}

/// Accept only full snapshots received through an authenticated, membership-checked channel.
/// Gaps are safe for full snapshots; deltas would require contiguous sequence checking.
struct FriendsReplica {
    let sessionID: UUID
    let accountID: UUID
    private(set) var snapshot: FriendsSnapshot?
    private(set) var connected = false

    init(sessionID: UUID, accountID: UUID) {
        self.sessionID = sessionID
        self.accountID = accountID
    }

    mutating func disconnect() { connected = false }

    /// Startup-only cache hydration validates structure/identity without implying a live connection.
    mutating func restoreCachedSnapshot(_ cached: FriendsSnapshot) throws {
        guard snapshot == nil else { throw FriendsError.invalidSnapshot }
        try receive(cached)
        connected = false
    }

    @discardableResult
    mutating func receive(_ incoming: FriendsSnapshot) throws -> Bool {
        guard incoming.sessionID == sessionID else { throw FriendsError.wrongSession }
        guard incoming.isValid else { throw FriendsError.invalidSnapshot }
        guard incoming.members.contains(where: { $0.accountID == accountID }) else {
            throw FriendsError.forbidden
        }
        if let previous = snapshot {
            if incoming.revision < previous.revision { return false }
            if incoming.revision == previous.revision {
                guard incoming == previous else { throw FriendsError.conflictingRevision }
                connected = true
                return false
            }
            guard incoming.ownerID == previous.ownerID else { throw FriendsError.identityChanged }
            // No membership removal/transfer exists in this minimal contract.
            for member in previous.members {
                guard incoming.members.contains(where: {
                    $0.accountID == member.accountID && $0.participantID == member.participantID
                }) else { throw FriendsError.identityChanged }
            }
            let order: [FriendsPhase] = [.lobby, .studying, .finished]
            guard order.firstIndex(of: incoming.phase)! >= order.firstIndex(of: previous.phase)!,
                  previous.phase == .lobby || (incoming.members.count == previous.members.count &&
                    previous.members.allSatisfy { member in
                        incoming.members.first(where: { $0.accountID == member.accountID })?.sharedIntent == member.sharedIntent
                    }) else {
                throw FriendsError.invalidSnapshot
            }
        }
        snapshot = incoming
        connected = true
        return true
    }
}

/// The adapter derives recipientID from its authenticated channel, not an untrusted payload.
struct FriendsEnvelope: Codable, Equatable {
    let recipientID: UUID
    let snapshot: FriendsSnapshot
}

/// Pure lifecycle contract for an eventual transport. No sockets, credentials or timers.
/// A new random token identifies each connection attempt; callbacks must retain that token.
struct FriendsConnection {
    enum State: Equatable { case disconnected, refreshing, ready }
    let sessionID: UUID
    let accountID: UUID
    private var replica: FriendsReplica
    private(set) var generation: UUID?
    private(set) var state: State = .disconnected
    var snapshot: FriendsSnapshot? { replica.snapshot }
    var controlsEnabled: Bool { state == .ready }

    init(sessionID: UUID, accountID: UUID) {
        self.sessionID = sessionID
        self.accountID = accountID
        replica = FriendsReplica(sessionID: sessionID, accountID: accountID)
    }

    mutating func restoreCachedSnapshot(_ cached: FriendsEnvelope) throws {
        guard generation == nil, state == .disconnected else { throw FriendsError.invalidPhase }
        try validateRecipient(cached)
        try replica.restoreCachedSnapshot(cached.snapshot)
    }

    @discardableResult
    mutating func beginReconnect() -> UUID {
        let token = UUID()
        generation = token
        state = .refreshing
        replica.disconnect()
        return token
    }

    mutating func disconnect(generation token: UUID) {
        guard generation == token else { return }
        generation = nil
        state = .disconnected
        replica.disconnect()
    }

    /// A stream frame never counts as the membership-checked reconnect read.
    @discardableResult
    mutating func receiveStream(_ envelope: FriendsEnvelope, generation token: UUID) throws -> Bool {
        guard generation == token, state == .ready else { return false }
        return try accept(envelope)
    }

    /// Adapter must invoke only for its fresh authenticated, membership-checked request.
    @discardableResult
    mutating func receiveFreshRead(_ envelope: FriendsEnvelope, generation token: UUID) throws -> Bool {
        guard generation == token, state == .refreshing else { return false }
        let changed = try accept(envelope)
        // A response older than our cache cannot establish freshness.
        guard envelope.snapshot.revision == snapshot?.revision else { return false }
        state = .ready
        return changed
    }

    /// Permission denial invalidates private cached contents; ordinary network loss does not.
    mutating func accessDenied(generation token: UUID) {
        guard generation == token else { return }
        generation = nil
        state = .disconnected
        replica = FriendsReplica(sessionID: sessionID, accountID: accountID)
    }

    func commandRevision() throws -> Int {
        guard controlsEnabled, let snapshot else { throw FriendsError.disconnected }
        return snapshot.revision
    }

    private func validateRecipient(_ envelope: FriendsEnvelope) throws {
        guard envelope.recipientID == accountID else { throw FriendsError.wrongRecipient }
    }

    private mutating func accept(_ envelope: FriendsEnvelope) throws -> Bool {
        do {
            try validateRecipient(envelope)
            return try replica.receive(envelope.snapshot)
        } catch {
            // Contradiction/invalid payload requires another fresh read, never enabled controls.
            generation = nil
            state = .disconnected
            replica.disconnect()
            throw error
        }
    }
}
