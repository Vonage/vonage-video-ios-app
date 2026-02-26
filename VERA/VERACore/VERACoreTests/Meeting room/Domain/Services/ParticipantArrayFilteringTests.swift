//
//  Created by Vonage on 26/02/2026.
//

import Foundation
import SwiftUI
import Testing
import VERADomain
import VERATestHelpers

@testable import VERACore

@Suite("Participant array filtering tests")
struct ParticipantArrayFilteringTests {

    @Test("filter returns full list if searchText is empty")
    func filterReturnsFullList() {
        let participants = [
            makeMockParticipant(id: "1", name: "John"),
            makeMockParticipant(id: "2", name: "Alice"),
        ]

        let result = participants.filtered(by: "")

        #expect(result.count == 2)
        #expect(result.map { $0.name }.contains("John"))
        #expect(result.map { $0.name }.contains("Alice"))
    }

    @Test("filter returns only participants that match searchText")
    func filterReturnsMatchingParticipants() {
        let participants = [
            makeMockParticipant(id: "1", name: "John"),
            makeMockParticipant(id: "2", name: "Alice"),
        ]

        let result = participants.filtered(by: "John")

        #expect(result.count == 1)
        #expect(result.first?.name == "John")
    }

    @Test("filter returns empty array when no participants match")
    func filterReturnsEmptyWhenNoMatch() {
        let participants = [
            makeMockParticipant(id: "1", name: "John"),
            makeMockParticipant(id: "2", name: "Alice"),
        ]

        let result = participants.filtered(by: "Bob")

        #expect(result.isEmpty)
    }

    @Test("filter is case-insensitive")
    func filterIgnoresCase() {
        let participants = [
            makeMockParticipant(id: "1", name: "John"),
            makeMockParticipant(id: "2", name: "Alice"),
        ]

        let result = participants.filtered(by: "john")

        #expect(result.count == 1)
        #expect(result.first?.name == "John")
    }

    @Test("filter is diacritic-insensitive")
    func filterIgnoresDiacritics() {
        let participants = [
            makeMockParticipant(id: "1", name: "José"),
            makeMockParticipant(id: "2", name: "Alice"),
        ]

        let result = participants.filtered(by: "Jose")

        #expect(result.count == 1)
        #expect(result.first?.name == "José")
    }
}
