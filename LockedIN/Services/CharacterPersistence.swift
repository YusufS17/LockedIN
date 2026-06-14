import Foundation

// MARK: - PersistenceKeys (ONB-04, RESEARCH.md Pitfall 5)
//
// Single source of truth for all UserDefaults key strings.
// NEVER hardcode key strings at the call site — always reference these constants.
// Applies to @AppStorage in Views (use PersistenceKeys.onboarding) and
// CharacterPersistence save/load calls (character, displayName).

enum PersistenceKeys {
    static let character        = "userCharacterAppearance"
    static let displayName      = "userDisplayName"
    static let onboarding       = "hasCompletedOnboarding"
    static let selectedCharacter = "selectedCharacterID"
}

// MARK: - CharacterPersistence (ONB-04)
//
// Lightweight UserDefaults + JSONEncoder/Decoder wrapper for identity persistence.
// Caseless enum used as a namespace (same pattern as Money.swift utility enum).
//
// Security:
//  - T-02-03 (DoS/crash): try? on all decode operations — failure silently returns nil;
//    caller falls back to CharacterAppearance.default. No force-unwrap.
//  - T-02-05 (logging): display name and appearance are never printed/logged here.

enum CharacterPersistence {

    // MARK: - PersistedIdentity

    /// The bundle of user identity values loaded from or saved to UserDefaults.
    struct PersistedIdentity {
        let appearance: CharacterAppearance
        let displayName: String
    }

    // MARK: - Save

    /// Persists the user's chosen appearance and display name to UserDefaults.
    ///
    /// Appearance is JSON-encoded; display name is stored as a plain string.
    /// Silent on encoding failure — avoids crashing on an edge-case encode error.
    static func save(appearance: CharacterAppearance, displayName: String) {
        if let data = try? JSONEncoder().encode(appearance) {
            UserDefaults.standard.set(data, forKey: PersistenceKeys.character)
        }
        UserDefaults.standard.set(displayName, forKey: PersistenceKeys.displayName)
    }

    // MARK: - Load

    /// Loads persisted identity from UserDefaults.
    ///
    /// Returns `nil` if:
    ///  - No character data has been written yet (clean state / first launch)
    ///  - The stored character data is undecodable (corrupt / schema-changed after update)
    ///
    /// Never force-unwraps decode results (T-02-03: stale-data DoS threat mitigation).
    static func load() -> PersistedIdentity? {
        guard
            let data = UserDefaults.standard.data(forKey: PersistenceKeys.character),
            let appearance = try? JSONDecoder().decode(CharacterAppearance.self, from: data)
        else { return nil }

        let name = UserDefaults.standard.string(forKey: PersistenceKeys.displayName) ?? ""
        return PersistedIdentity(appearance: appearance, displayName: name)
    }
}

// MARK: - Debug Self-Check (round-trip + nil-on-clean-state verification)

#if DEBUG
import SwiftUI

struct PersistenceSelfCheckView: View {
    @State private var result: String = "Running…"

    var body: some View {
        VStack(spacing: 16) {
            Text("CharacterPersistence — Self-Check")
                .font(.headline)
            Text(result)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .task { await runSelfCheck() }
    }

    private func runSelfCheck() async {
        var passes: [String] = []
        var failures: [String] = []

        // 1. nil-on-clean-state: remove any existing character data before checking
        UserDefaults.standard.removeObject(forKey: PersistenceKeys.character)
        UserDefaults.standard.removeObject(forKey: PersistenceKeys.displayName)
        if CharacterPersistence.load() == nil {
            passes.append("nil on clean state")
        } else {
            failures.append("FAIL: expected nil on clean state, got non-nil")
        }

        // 2. Round-trip: save then load and compare
        let testAppearance = CharacterAppearance(
            skinTone: .dark,
            hairStyle: .curly,
            hairColour: .silver,
            outfitStyle: .hoodie,
            accentColour: .teal
        )
        let testName = "RoundTripTestUser"
        CharacterPersistence.save(appearance: testAppearance, displayName: testName)
        if let loaded = CharacterPersistence.load() {
            if loaded.appearance == testAppearance {
                passes.append("appearance round-trip match")
            } else {
                failures.append("FAIL: appearance mismatch after round-trip")
            }
            if loaded.displayName == testName {
                passes.append("displayName round-trip match")
            } else {
                failures.append("FAIL: displayName mismatch after round-trip")
            }
        } else {
            failures.append("FAIL: load() returned nil after save()")
        }

        // 3. Corrupt data: inject undecodable bytes → load() must return nil (T-02-03)
        UserDefaults.standard.set(Data([0xFF, 0xFE, 0x00]), forKey: PersistenceKeys.character)
        if CharacterPersistence.load() == nil {
            passes.append("nil on corrupt data (T-02-03 safe)")
        } else {
            failures.append("FAIL: expected nil on corrupt data, got non-nil")
        }

        // Clean up after self-check
        UserDefaults.standard.removeObject(forKey: PersistenceKeys.character)
        UserDefaults.standard.removeObject(forKey: PersistenceKeys.displayName)

        let summary = failures.isEmpty
            ? "PASS ✓ — \(passes.count) checks: \(passes.joined(separator: ", "))"
            : "FAIL ✗ — \(failures.joined(separator: "; "))"
        result = summary
    }
}

#Preview("Persistence round-trip self-check") {
    PersistenceSelfCheckView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
}
#endif
