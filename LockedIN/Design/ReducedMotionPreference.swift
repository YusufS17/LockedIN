import SwiftUI

/// Always respects iOS Reduce Motion. Isolated Debug layout checks can also opt in
/// without attempting to write SwiftUI's read-only system environment value.
@propertyWrapper
struct ReducedMotionPreference: DynamicProperty {
    @Environment(\.accessibilityReduceMotion) private var systemValue

    init() {}

    var wrappedValue: Bool {
        systemValue || StudyTestEnvironment.reducedMotionForChecks
    }
}
