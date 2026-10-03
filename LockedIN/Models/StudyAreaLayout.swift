import Foundation

/// Stable roster indices, balanced across rooms that can each clearly show four
/// people. Paging never creates new participants or changes reward identities.
enum StudyAreaLayout {
    static func indices(participantCount: Int) -> [[Int]] {
        guard participantCount > 0 else { return [] }
        let areaCount = (participantCount + 3) / 4
        let baseCount = participantCount / areaCount
        let extraCount = participantCount % areaCount
        var start = 0
        return (0..<areaCount).map { area in
            let count = baseCount + (area < extraCount ? 1 : 0)
            defer { start += count }
            return Array(start..<(start + count))
        }
    }

    static func area(containing participantIndex: Int, participantCount: Int) -> Int? {
        indices(participantCount: participantCount).firstIndex { $0.contains(participantIndex) }
    }
}
