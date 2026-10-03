import Foundation

@main
struct StudyAreaLayoutChecks {
    static func main() {
        assert(StudyAreaLayout.indices(participantCount: 0).isEmpty)
        assert(StudyAreaLayout.indices(participantCount: -1).isEmpty)
        let expectedCounts = [1: [1], 2: [2], 3: [3], 4: [4],
                              5: [3, 2], 6: [3, 3], 7: [4, 3], 8: [4, 4]]
        for count in 1...8 {
            let roster = (0..<count).map { _ in UUID() }
            let areas = StudyAreaLayout.indices(participantCount: count)
            assert(areas.map(\.count) == expectedCounts[count])
            let flattened = areas.flatMap { $0 }
            assert(flattened == Array(roster.indices), "Every participant must appear exactly once, in stable order")
            assert(flattened.map { roster[$0] } == roster, "Changing area must preserve participant UUIDs")
            for userIndex in roster.indices {
                let selected = StudyAreaLayout.area(containing: userIndex, participantCount: count)!
                assert(areas[selected].contains(userIndex), "A break must select the user's actual area")
                assert(areas.filter { $0.contains(userIndex) }.count == 1,
                       "The break occupant must not be duplicated across rooms")
                assert(areas[selected].firstIndex(of: userIndex) != nil,
                       "A global user index must resolve to a visible seat")
            }
            assert(StudyAreaLayout.area(containing: -1, participantCount: count) == nil)
            assert(StudyAreaLayout.area(containing: count, participantCount: count) == nil)
        }
        // Unexpected oversized data still has a unique seat for each participant;
        // the production session's capacity rule is responsible for rejecting it.
        assert(StudyAreaLayout.indices(participantCount: 9).map(\.count) == [3, 3, 3])
        print("Study area checks passed: balanced 1–8-person areas, stable indices and break membership")
    }
}
