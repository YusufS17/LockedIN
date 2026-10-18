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
//  - T-02-03 (DoS/crash): try? on all decode operations — failure returns nil;
//    caller falls back to CharacterAppearance.default. No force-unwrap.
//  - T-02-05 (logging): display name and appearance are never printed/logged here.

enum CharacterPersistence {

    // MARK: - PersistedIdentity

    /// The bundle of user identity values loaded from or saved to UserDefaults.
    struct PersistedIdentity {
        let appearance: CharacterAppearance
        let displayName: String
    }

    // MARK: - Protected identity storage

    /// Refuse to replace unreadable or newer identity data, including its separate name.
    @discardableResult
    static func save(appearance: CharacterAppearance, displayName: String, defaults: UserDefaults = .standard) -> Bool {
        guard recoveryIssue(defaults: defaults) == nil,
              let data = try? JSONEncoder().encode(appearance) else { return false }
        defaults.set(data, forKey: PersistenceKeys.character)
        defaults.set(displayName, forKey: PersistenceKeys.displayName)
        return true
    }

    static let recoveryMessage = "Your saved avatar could not be opened by this version of LockedIN. Editing is paused to keep your original look and name safe. Try opening it with the latest version."

    /// Missing wardrobe axes are supported legacy data. Unknown fields or enum values
    /// may belong to a newer app; do not silently decode and discard them on save.
    static func recoveryIssue(defaults: UserDefaults = .standard) -> String? {
        if let name = defaults.object(forKey: PersistenceKeys.displayName), !(name is String) {
            return recoveryMessage
        }
        guard let raw = defaults.object(forKey: PersistenceKeys.character) else { return nil }
        guard let data = raw as? Data, supportedAppearance(data) != nil else { return recoveryMessage }
        return nil
    }

    private static func supportedAppearance(_ data: Data) -> CharacterAppearance? {
        let required: Set<String> = ["skinTone", "hairStyle", "hairColour", "outfitStyle", "accentColour"]
        let supported = required.union(["faceStyle", "topStyle", "bottomStyle", "shoeStyle", "accessory"])
        guard let fields = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              required.isSubset(of: Set(fields.keys)), Set(fields.keys).isSubset(of: supported),
              fields.values.allSatisfy({ $0 is String }) else { return nil }
        return try? JSONDecoder().decode(CharacterAppearance.self, from: data)
    }

    /// The separate name remains available even when appearance recovery is needed.
    static func savedDisplayName(defaults: UserDefaults = .standard) -> String {
        defaults.object(forKey: PersistenceKeys.displayName) as? String ?? ""
    }

    static func load(defaults: UserDefaults = .standard) -> PersistedIdentity? {
        guard recoveryIssue(defaults: defaults) == nil,
              let data = defaults.data(forKey: PersistenceKeys.character),
              let appearance = supportedAppearance(data) else { return nil }
        return PersistedIdentity(appearance: appearance, displayName: savedDisplayName(defaults: defaults))
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
        let suite = "LockedIN.persistence-self-check.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            result = "Could not create isolated self-check storage."
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }

        var passes: [String] = []
        var failures: [String] = []

        // 1. Verify a fresh disposable suite; never touch the saved user identity.
        defaults.removeObject(forKey: PersistenceKeys.character)
        defaults.removeObject(forKey: PersistenceKeys.displayName)
        if CharacterPersistence.load(defaults: defaults) == nil {
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
        CharacterPersistence.save(appearance: testAppearance, displayName: testName, defaults: defaults)
        if let loaded = CharacterPersistence.load(defaults: defaults) {
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
        defaults.set(Data([0xFF, 0xFE, 0x00]), forKey: PersistenceKeys.character)
        if CharacterPersistence.load(defaults: defaults) == nil {
            passes.append("nil on corrupt data (T-02-03 safe)")
        } else {
            failures.append("FAIL: expected nil on corrupt data, got non-nil")
        }

        // Clean up after self-check
        defaults.removeObject(forKey: PersistenceKeys.character)
        defaults.removeObject(forKey: PersistenceKeys.displayName)

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
