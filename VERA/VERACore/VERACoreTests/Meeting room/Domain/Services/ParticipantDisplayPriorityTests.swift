//
//  Created by Vonage on 14/8/25.
//

import Foundation
import SwiftUI
import Testing
import VERATestHelpers

@testable import VERACore

@Suite("Participant display priority tests")
struct ParticipantDisplayPriorityTests {

    // MARK: - Display Priority Tests

    @Test("Screenshare participants have highest priority")
    func testScreenshareParticipantsHighestPriority() async throws {
        let participants = [
            makeMockParticipant(
                id: "1", name: "Regular", creationTime: Date(timeIntervalSince1970: 1000), isScreenshare: false),
            makeMockParticipant(
                id: "2", name: "Screenshare", creationTime: Date(timeIntervalSince1970: 2000), isScreenshare: true),
            makeMockParticipant(
                id: "3", name: "Another Regular", creationTime: Date(timeIntervalSince1970: 500), isScreenshare: false),
        ]

        let sorted = participants.sortedByDisplayPriority(activeSpeakerId: nil)

        // Screenshare first, then regular participants ordered by creation time (3 before 1)
        #expect(sorted.map(\.id) == ["2", "3", "1"])
    }

    @Test("Multiple screenshare participants maintain order")
    func testMultipleScreenshareParticipants() async throws {
        let participants = [
            makeMockParticipant(
                id: "1", name: "Regular", creationTime: Date(timeIntervalSince1970: 1000), isScreenshare: false),
            makeMockParticipant(
                id: "2", name: "Screenshare1", creationTime: Date(timeIntervalSince1970: 2000), isScreenshare: true),
            makeMockParticipant(
                id: "3", name: "Screenshare2", creationTime: Date(timeIntervalSince1970: 1500), isScreenshare: true),
            makeMockParticipant(
                id: "4", name: "Another Regular", creationTime: Date(timeIntervalSince1970: 500), isScreenshare: false),
        ]

        let sorted = participants.sortedByDisplayPriority(activeSpeakerId: nil)

        // Screenshare participants by creation time (3 before 2), then regular participants by creation time (4 before 1)
        #expect(sorted.map(\.id) == ["3", "2", "4", "1"])
    }

    @Test("Pinned participants come after screenshare")
    func testPinnedParticipantsPriority() async throws {
        let participants = [
            makeMockParticipant(
                id: "1",
                name: "Regular",
                creationTime: Date(timeIntervalSince1970: 1000),
                isScreenshare: false,
                isPinned: false),
            makeMockParticipant(
                id: "2",
                name: "Pinned",
                creationTime: Date(timeIntervalSince1970: 1500),
                isScreenshare: false,
                isPinned: true),
            makeMockParticipant(
                id: "3",
                name: "Screenshare",
                creationTime: Date(timeIntervalSince1970: 2000),
                isScreenshare: true,
                isPinned: false),
        ]

        let sorted = participants.sortedByDisplayPriority(activeSpeakerId: nil)

        #expect(sorted.map(\.id) == ["3", "2", "1"])
    }

    @Test("Multiple pinned participants maintain order")
    func testMultiplePinnedParticipants() async throws {
        let participants = [
            makeMockParticipant(
                id: "1", name: "Regular", creationTime: Date(timeIntervalSince1970: 1000), isPinned: false),
            makeMockParticipant(
                id: "2", name: "Pinned1", creationTime: Date(timeIntervalSince1970: 2000), isPinned: true),
            makeMockParticipant(
                id: "3", name: "Pinned2", creationTime: Date(timeIntervalSince1970: 1500), isPinned: true),
            makeMockParticipant(
                id: "4", name: "Another Regular", creationTime: Date(timeIntervalSince1970: 500), isPinned: false),
        ]

        let sorted = participants.sortedByDisplayPriority(activeSpeakerId: nil)

        // Pinned participants maintain current order (2, 3), then regular participants by creation time (4 before 1)
        #expect(sorted.map(\.id) == ["2", "3", "4", "1"])
    }

    @Test("Active speaker comes after pinned participants")
    func testActiveSpeakerPriority() async throws {
        let participants = [
            makeMockParticipant(
                id: "1", name: "Regular", creationTime: Date(timeIntervalSince1970: 1000), isPinned: false),
            makeMockParticipant(
                id: "2", name: "Speaker", creationTime: Date(timeIntervalSince1970: 1500), isPinned: false),
            makeMockParticipant(
                id: "3", name: "Pinned", creationTime: Date(timeIntervalSince1970: 2000), isPinned: true),
        ]

        let sorted = participants.sortedByDisplayPriority(activeSpeakerId: "2")

        #expect(sorted.map(\.id) == ["3", "2", "1"])
    }

    @Test("Pinned active speaker has pinned priority")
    func testPinnedActiveSpeaker() async throws {
        let participants = [
            makeMockParticipant(
                id: "1", name: "Regular", creationTime: Date(timeIntervalSince1970: 1000), isPinned: false),
            makeMockParticipant(
                id: "2", name: "PinnedSpeaker", creationTime: Date(timeIntervalSince1970: 1500), isPinned: true),
            makeMockParticipant(
                id: "3", name: "Pinned", creationTime: Date(timeIntervalSince1970: 2000), isPinned: true),
        ]

        let sorted = participants.sortedByDisplayPriority(activeSpeakerId: "2")

        #expect(sorted.map(\.id) == ["2", "3", "1"])
    }

    @Test("Complex priority hierarchy")
    func testComplexPriorityHierarchy() async throws {
        let participants = [
            makeMockParticipant(
                id: "1",
                name: "Regular1",
                creationTime: Date(timeIntervalSince1970: 2000),
                isScreenshare: false,
                isPinned: false),
            makeMockParticipant(
                id: "2",
                name: "ActiveSpeaker",
                creationTime: Date(timeIntervalSince1970: 1500),
                isScreenshare: false,
                isPinned: false),
            makeMockParticipant(
                id: "3",
                name: "Pinned1",
                creationTime: Date(timeIntervalSince1970: 3000),
                isScreenshare: false,
                isPinned: true),
            makeMockParticipant(
                id: "4",
                name: "Screenshare1",
                creationTime: Date(timeIntervalSince1970: 3500),
                isScreenshare: true,
                isPinned: false),
            makeMockParticipant(
                id: "5",
                name: "ScreensharePinned",
                creationTime: Date(timeIntervalSince1970: 2500),
                isScreenshare: true,
                isPinned: true),
            makeMockParticipant(
                id: "6",
                name: "Regular2",
                creationTime: Date(timeIntervalSince1970: 1000),
                isScreenshare: false,
                isPinned: false),
            makeMockParticipant(
                id: "7",
                name: "Pinned2",
                creationTime: Date(timeIntervalSince1970: 4000),
                isScreenshare: false,
                isPinned: true),
        ]

        let sorted = participants.sortedByDisplayPriority(activeSpeakerId: "2")

        // Expected order:
        // - Screenshare by creation time (5 before 4)
        // - Pinned maintain order (3, 7)
        // - ActiveSpeaker (2)
        // - Regular by creation time (6 before 1)
        #expect(sorted.map(\.id) == ["5", "4", "3", "7", "2", "6", "1"])
    }

    @Test("No active speaker specified")
    func testNoActiveSpeaker() async throws {
        let participants = [
            makeMockParticipant(id: "1", name: "Regular1", creationTime: Date(timeIntervalSince1970: 2000)),
            makeMockParticipant(id: "2", name: "Regular2", creationTime: Date(timeIntervalSince1970: 1000)),
            makeMockParticipant(id: "3", name: "Regular3", creationTime: Date(timeIntervalSince1970: 1500)),
        ]

        let sorted = participants.sortedByDisplayPriority(activeSpeakerId: nil)

        // Ordered by creation time: 2, 3, 1
        #expect(sorted.map(\.id) == ["2", "3", "1"])
    }

    @Test("Empty participants array")
    func testEmptyParticipantsArray() async throws {
        let participants: [Participant] = []

        let sorted = participants.sortedByDisplayPriority(activeSpeakerId: "1")

        #expect(sorted.isEmpty)
    }

    @Test("Single participant")
    func testSingleParticipant() async throws {
        let participants = [
            makeMockParticipant(id: "1", name: "OnlyOne", creationTime: Date(timeIntervalSince1970: 1000))
        ]

        let sorted = participants.sortedByDisplayPriority(activeSpeakerId: "1")

        #expect(sorted.map(\.id) == ["1"])
    }

    // MARK: - Static Method Tests

    @Test("Static sortByDisplayPriority method")
    func testStaticSortByDisplayPriorityMethod() async throws {
        let participants = [
            makeMockParticipant(id: "1", name: "Regular", creationTime: Date(timeIntervalSince1970: 1000)),
            makeMockParticipant(id: "2", name: "Speaker", creationTime: Date(timeIntervalSince1970: 1500)),
            makeMockParticipant(
                id: "3", name: "Pinned", creationTime: Date(timeIntervalSince1970: 2000), isPinned: true),
        ]

        let sorted = ParticipantDisplayPriority.sortByDisplayPriority(
            participants: participants,
            activeSpeakerId: "2"
        )

        #expect(sorted.map(\.id) == ["3", "2", "1"])
    }

    // MARK: - Edge Cases

    @Test("Participant with all special properties")
    func testParticipantWithAllSpecialProperties() async throws {
        let participants = [
            makeMockParticipant(id: "1", name: "Regular", creationTime: Date(timeIntervalSince1970: 1000)),
            makeMockParticipant(
                id: "2", name: "SuperParticipant", creationTime: Date(timeIntervalSince1970: 1500), isScreenshare: true,
                isPinned: true),
        ]

        let sorted = participants.sortedByDisplayPriority(activeSpeakerId: "2")

        #expect(sorted.map(\.id) == ["2", "1"])
    }

    // MARK: - Creation Date Sorting Tests

    @Test("Participants with identical names sorted by creation date")
    func testIdenticalNamesSortedByCreationDate() async throws {
        let participants = [
            makeMockParticipant(id: "1", name: "John", creationTime: Date(timeIntervalSince1970: 2000)),
            makeMockParticipant(id: "2", name: "John", creationTime: Date(timeIntervalSince1970: 1000)),
            makeMockParticipant(id: "3", name: "John", creationTime: Date(timeIntervalSince1970: 1500)),
        ]

        let sorted = participants.sortedByDisplayPriority(activeSpeakerId: nil)

        // Should be sorted by creation time when names are identical
        #expect(sorted.map(\.id) == ["2", "3", "1"])
    }

    @Test("Participants with identical creation times sorted by name")
    func testIdenticalCreationTimesSortedByName() async throws {
        let sameTime = Date(timeIntervalSince1970: 1000)
        let participants = [
            makeMockParticipant(id: "1", name: "Charlie", creationTime: sameTime),
            makeMockParticipant(id: "2", name: "Alice", creationTime: sameTime),
            makeMockParticipant(id: "3", name: "Bob", creationTime: sameTime),
        ]

        let sorted = participants.sortedByDisplayPriority(activeSpeakerId: nil)

        // Should be sorted alphabetically when creation times are identical
        #expect(sorted.map(\.id) == ["2", "3", "1"])
    }
}
