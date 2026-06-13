import Foundation

// MARK: - Participant Settlement State (D-11, FND-04)

/// The 8 canonical participant settlement states.
/// These are EXACTLY the 8 states from ROADMAP success criterion #3 — non-negotiable.
/// No additional cases may be added without updating D-11.
///
/// See threat register T-01-07: typed enum prevents ad-hoc/typo state.
enum ParticipantSettlementState: Equatable {

    /// Stake not required (e.g. host-only participant, no monetary agreement).
    case notRequired

    /// Awaiting authorisation from the payment provider.
    case awaitingAuthorisation

    /// Stake held/authorised; session in progress.
    /// Associated value: the HoldReference returned by CommitmentService.authoriseHold.
    case held(ref: HoldReference)

    /// Stake authorised for return (participant passed); settlement pending.
    case authorisedForReturn

    /// Stake authorised for forfeit (participant failed); settlement pending.
    case authorisedForForfeit

    /// Stake successfully returned to participant.
    /// Associated value: the SettlementRecord confirming the return.
    case returned(record: SettlementRecord)

    /// Stake successfully forfeited.
    /// Associated value: the SettlementRecord confirming the forfeit.
    case forfeited(record: SettlementRecord)

    /// An error occurred during settlement.
    /// Associated value: a non-empty diagnostic message (never shown raw to users).
    case settlementError(message: String)
}
