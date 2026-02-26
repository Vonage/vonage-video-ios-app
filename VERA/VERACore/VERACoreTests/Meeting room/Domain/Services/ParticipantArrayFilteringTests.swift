//
//  Created by Vonage on 26/02/2026.
//

import Foundation
import SwiftUI
import Testing
import VERADomain
import VERATestHelpers

@testable import VERACore

@Suite("Participant array sorting tests")
struct ParticipantArrayFilteringTests {

    @Test("matches returns true for exact match")
    func matchesReturnsTrueForExactMatch() {
        let participant = makeMockParticipant(id: "1", name: "John")

        #expect(participant.matches(searchText: "John"))
    }

    @Test("matches is case insensitive")
    func matchesIsCaseInsensitive() {
        let participant = makeMockParticipant(id: "1", name: "John")

        #expect(participant.matches(searchText: "john"))
    }

    @Test("matches is diacritic insensitive")
    func matchesIsDiacriticInsensitive() {
        let participant = makeMockParticipant(id: "1", name: "José")

        #expect(participant.matches(searchText: "jose"))
    }

    @Test("matches returns false when no match")
    func matchesReturnsFalseWhenNoMatch() {
        let participant = makeMockParticipant(id: "1", name: "John")

        #expect(!participant.matches(searchText: "zzz"))
    }
}
