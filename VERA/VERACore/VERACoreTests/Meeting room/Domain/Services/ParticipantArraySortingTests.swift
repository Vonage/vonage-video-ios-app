//
//  Created by Vonage on 14/8/25.
//

import Foundation
import SwiftUI
import Testing
import VERATestHelpers
import VERADomain

@testable import VERACore

@Suite("Participant array sorting tests")
struct ParticipantArraySortingTests {

    // MARK: - Name Sorting Tests

    @Test("Basic alphabetical name sorting")
    func testBasicNameSorting() async throws {
        let participants = [
            makeMockParticipant(id: "1", name: "Charlie"),
            makeMockParticipant(id: "2", name: "Alice"),
            makeMockParticipant(id: "3", name: "Bob"),
        ]

        let sorted = participants.sortedByName()

        #expect(sorted.map(\.name) == ["Alice", "Bob", "Charlie"])
        #expect(sorted.map(\.id) == ["2", "3", "1"])
    }

    @Test("Case insensitive name sorting")
    func testCaseInsensitiveNameSorting() async throws {
        let participants = [
            makeMockParticipant(id: "1", name: "charlie"),
            makeMockParticipant(id: "2", name: "Alice"),
            makeMockParticipant(id: "3", name: "BOB"),
            makeMockParticipant(id: "4", name: "dave"),
        ]

        let sorted = participants.sortedByName()

        #expect(sorted.map(\.name) == ["Alice", "BOB", "charlie", "dave"])
    }

    @Test("Diacritic insensitive name sorting")
    func testDiacriticInsensitiveNameSorting() async throws {
        let participants = [
            makeMockParticipant(id: "1", name: "Zoë"),
            makeMockParticipant(id: "2", name: "José"),
            makeMockParticipant(id: "3", name: "jose"),
            makeMockParticipant(id: "4", name: "Alice"),
            makeMockParticipant(id: "5", name: "Étienne"),
        ]

        let sorted = participants.sortedByName()

        #expect(sorted.map(\.name) == ["Alice", "Étienne", "jose", "José", "Zoë"])
    }

    @Test("Names with special characters sorting")
    func testSpecialCharacterNameSorting() async throws {
        let participants = [
            makeMockParticipant(id: "1", name: "O'Connor"),
            makeMockParticipant(id: "2", name: "McDonald"),
            makeMockParticipant(id: "3", name: "Van Der Berg"),
            makeMockParticipant(id: "4", name: "Al-Ahmad"),
        ]

        let sorted = participants.sortedByName()

        #expect(sorted.map(\.name) == ["Al-Ahmad", "McDonald", "O'Connor", "Van Der Berg"])
    }

    @Test("Numeric sorting in names")
    func testNumericNameSorting() async throws {
        let participants = [
            makeMockParticipant(id: "1", name: "User 10"),
            makeMockParticipant(id: "2", name: "User 2"),
            makeMockParticipant(id: "3", name: "User 1"),
            makeMockParticipant(id: "4", name: "User 20"),
        ]

        let sorted = participants.sortedByName()

        #expect(sorted.map(\.name) == ["User 1", "User 2", "User 10", "User 20"])
    }

    @Test("Empty and single participant name sorting")
    func testEdgeCaseNameSorting() async throws {
        let emptyParticipants: [Participant] = []
        #expect(emptyParticipants.sortedByName().isEmpty)

        let singleParticipant = [makeMockParticipant(id: "1", name: "Alice")]
        #expect(singleParticipant.sortedByName().map(\.name) == ["Alice"])
    }

    @Test("Name sorting with creation time tiebreaker for identical names")
    func testNameSortingWithCreationTimeTiebreaker() async throws {
        let baseTime = Date()
        let participants = [
            makeMockParticipant(id: "1", name: "John", creationTime: baseTime.addingTimeInterval(300)),  // Latest John
            makeMockParticipant(id: "2", name: "John", creationTime: baseTime.addingTimeInterval(100)),  // Middle John
            makeMockParticipant(id: "3", name: "John", creationTime: baseTime),  // Earliest John
            makeMockParticipant(id: "4", name: "Alice", creationTime: baseTime.addingTimeInterval(50)),  // Alice
        ]

        let sorted = participants.sortedByName()

        // Alice should come first alphabetically
        #expect(sorted[0].name == "Alice")
        #expect(sorted[0].id == "4")

        // Johns should be sorted by creation time (earliest first)
        #expect(sorted[1].name == "John")
        #expect(sorted[1].id == "3")  // Earliest John (baseTime)

        #expect(sorted[2].name == "John")
        #expect(sorted[2].id == "2")  // Middle John (baseTime + 100)

        #expect(sorted[3].name == "John")
        #expect(sorted[3].id == "1")  // Latest John (baseTime + 300)
    }

    @Test("Identical names sorting with creation time tiebreaker")
    func testIdenticalNamesSorting() async throws {
        let baseTime = Date()
        let participants = [
            makeMockParticipant(id: "1", name: "John", creationTime: baseTime.addingTimeInterval(100)),
            makeMockParticipant(id: "2", name: "Alice", creationTime: baseTime),
            makeMockParticipant(id: "3", name: "John", creationTime: baseTime.addingTimeInterval(50)),
            makeMockParticipant(id: "4", name: "Alice", creationTime: baseTime.addingTimeInterval(200)),
        ]

        let sorted = participants.sortedByName()

        #expect(sorted.map(\.name) == ["Alice", "Alice", "John", "John"])
        // Should sort by creation time when names are identical (earliest first)
        #expect(sorted[0].id == "2")  // Alice with baseTime (earliest)
        #expect(sorted[1].id == "4")  // Alice with baseTime + 200 (later)
        #expect(sorted[2].id == "3")  // John with baseTime + 50 (earlier)
        #expect(sorted[3].id == "1")  // John with baseTime + 100 (later)
    }

    // MARK: - Date Sorting Tests

    @Test("Basic creation date sorting")
    func testBasicDateSorting() async throws {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let twoHoursAgo = now.addingTimeInterval(-7200)

        let participants = [
            makeMockParticipant(id: "1", name: "Latest", creationTime: now),
            makeMockParticipant(id: "2", name: "Earliest", creationTime: twoHoursAgo),
            makeMockParticipant(id: "3", name: "Middle", creationTime: oneHourAgo),
        ]

        let sorted = participants.sortedByCreationDate()

        #expect(sorted.map(\.name) == ["Earliest", "Middle", "Latest"])
        #expect(sorted.map(\.id) == ["2", "3", "1"])
    }

    @Test("Same creation time sorting with name tiebreaker")
    func testSameCreationTimeSorting() async throws {
        let sameTime = Date()
        let participants = [
            makeMockParticipant(id: "1", name: "Charlie", creationTime: sameTime),
            makeMockParticipant(id: "2", name: "Alice", creationTime: sameTime),
            makeMockParticipant(id: "3", name: "Bob", creationTime: sameTime),
        ]

        let sorted = participants.sortedByCreationDate()

        // Should sort by name when creation times are identical
        #expect(sorted.map(\.name) == ["Alice", "Bob", "Charlie"])
        #expect(sorted.map(\.id) == ["2", "3", "1"])
    }

    @Test("Creation date sorting with name tiebreaker for diacritics")
    func testCreationDateSortingWithDiacriticNameTiebreaker() async throws {
        let sameTime = Date()
        let participants = [
            makeMockParticipant(id: "1", name: "Zoë", creationTime: sameTime),
            makeMockParticipant(id: "2", name: "José", creationTime: sameTime),
            makeMockParticipant(id: "3", name: "alice", creationTime: sameTime),
            makeMockParticipant(id: "4", name: "BOB", creationTime: sameTime),
        ]

        let sorted = participants.sortedByCreationDate()

        // Should sort by name (case and diacritic insensitive) when creation times are identical
        #expect(sorted.map(\.name) == ["alice", "BOB", "José", "Zoë"])
        #expect(sorted.map(\.id) == ["3", "4", "2", "1"])
    }

    @Test("Date sorting with multiple participants at same time")
    func testDateSortingWithMultipleParticipantsAtSameTime() async throws {
        let time1 = Date()
        let time2 = time1.addingTimeInterval(100)

        let participants = [
            makeMockParticipant(id: "1", name: "Zebra", creationTime: time1),
            makeMockParticipant(id: "2", name: "Alpha", creationTime: time1),
            makeMockParticipant(id: "3", name: "Beta", creationTime: time2),
            makeMockParticipant(id: "4", name: "Charlie", creationTime: time1),
            makeMockParticipant(id: "5", name: "Delta", creationTime: time2),
        ]

        let sorted = participants.sortedByCreationDate()

        // First group (time1): Alpha, Charlie, Zebra (sorted by name)
        // Second group (time2): Beta, Delta (sorted by name)
        #expect(sorted.map(\.name) == ["Alpha", "Charlie", "Zebra", "Beta", "Delta"])
        #expect(sorted.map(\.id) == ["2", "4", "1", "3", "5"])
    }

    @Test("Microsecond precision date sorting")
    func testMicrosecondPrecisionDateSorting() async throws {
        let baseTime = Date()
        let participants = [
            makeMockParticipant(id: "1", name: "Third", creationTime: baseTime.addingTimeInterval(0.002)),
            makeMockParticipant(id: "2", name: "First", creationTime: baseTime),
            makeMockParticipant(id: "3", name: "Second", creationTime: baseTime.addingTimeInterval(0.001)),
        ]

        let sorted = participants.sortedByCreationDate()

        #expect(sorted.map(\.name) == ["First", "Second", "Third"])
        #expect(sorted.map(\.id) == ["2", "3", "1"])
    }

    @Test("Large time range date sorting")
    func testLargeTimeRangeDateSorting() async throws {
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let lastWeek = now.addingTimeInterval(-604800)
        let lastMonth = now.addingTimeInterval(-2_592_000)

        let participants = [
            makeMockParticipant(id: "1", name: "Today", creationTime: now),
            makeMockParticipant(id: "2", name: "Last Month", creationTime: lastMonth),
            makeMockParticipant(id: "3", name: "Yesterday", creationTime: yesterday),
            makeMockParticipant(id: "4", name: "Last Week", creationTime: lastWeek),
        ]

        let sorted = participants.sortedByCreationDate()

        #expect(sorted.map(\.name) == ["Last Month", "Last Week", "Yesterday", "Today"])
        #expect(sorted.map(\.id) == ["2", "4", "3", "1"])
    }

    @Test("Empty and single participant date sorting")
    func testEdgeCaseDateSorting() async throws {
        let emptyParticipants: [Participant] = []
        #expect(emptyParticipants.sortedByCreationDate().isEmpty)

        let singleParticipant = [makeMockParticipant(id: "1", name: "Alice")]
        #expect(singleParticipant.sortedByCreationDate().map(\.name) == ["Alice"])
    }
}
