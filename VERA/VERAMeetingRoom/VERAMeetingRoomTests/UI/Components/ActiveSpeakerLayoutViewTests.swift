//
//  Created by Vonage on 12/5/26.
//

import Foundation
import SwiftUI
import Testing
import VERADomain
import VERATestHelpers

@testable import VERAMeetingRoom

@Suite("ActiveSpeakerLayout - mainAreaParticipants screen share prominence")
struct ActiveSpeakerLayoutViewTests {

    // MARK: - HorizontalActiveSpeakerLayoutView

    @Suite("HorizontalActiveSpeakerLayoutView")
    struct HorizontalLayoutTests {

        private func makeSUT(participants: [UIParticipant], activeSpeakerId: String?) -> HorizontalActiveSpeakerLayoutView {
            HorizontalActiveSpeakerLayoutView(participants: participants, activeSpeakerId: activeSpeakerId)
        }

        @Test("Active speaker is included in main area when no screen share is active")
        func activeSpeakerIsProminentWithoutScreenShare() {
            let activeSpeakerId = "active"
            let participants = [
                UIParticipant(participant: makeMockParticipant(id: "other"), isPinned: false),
                UIParticipant(participant: makeMockParticipant(id: activeSpeakerId), isPinned: false),
            ]

            let sut = makeSUT(participants: participants, activeSpeakerId: activeSpeakerId)

            #expect(sut.mainAreaParticipants.map(\.id) == ["other", activeSpeakerId])
        }

        @Test("Active speaker is NOT included in main area when screen share is active")
        func activeSpeakerExcludedFromMainAreaDuringScreenShare() {
            let screenShareId = "ss"
            let activeSpeakerId = "active"
            let participants = [
                UIParticipant(
                    participant: makeMockParticipant(id: screenShareId, isScreenshare: true), isPinned: false),
                UIParticipant(participant: makeMockParticipant(id: activeSpeakerId), isPinned: false),
                UIParticipant(participant: makeMockParticipant(id: "other"), isPinned: false),
            ]

            let sut = makeSUT(participants: participants, activeSpeakerId: activeSpeakerId)

            let mainIds = sut.mainAreaParticipants.map(\.id)
            #expect(mainIds.contains(screenShareId))
            #expect(!mainIds.contains(activeSpeakerId))
        }

        @Test("Pinned participant IS included in main area when screen share is active")
        func pinnedParticipantIsProminentDuringScreenShare() {
            let screenShareId = "ss"
            let pinnedId = "pinned"
            let activeSpeakerId = "active"
            let participants = [
                UIParticipant(
                    participant: makeMockParticipant(id: screenShareId, isScreenshare: true), isPinned: false),
                UIParticipant(participant: makeMockParticipant(id: pinnedId), isPinned: true),
                UIParticipant(participant: makeMockParticipant(id: activeSpeakerId), isPinned: false),
            ]

            let sut = makeSUT(participants: participants, activeSpeakerId: activeSpeakerId)

            let mainIds = sut.mainAreaParticipants.map(\.id)
            #expect(mainIds.contains(screenShareId))
            #expect(mainIds.contains(pinnedId))
            #expect(!mainIds.contains(activeSpeakerId))
        }
    }

    // MARK: - VerticalActiveSpeakerLayoutView

    @Suite("VerticalActiveSpeakerLayoutView")
    struct VerticalLayoutTests {

        private func makeSUT(participants: [UIParticipant], activeSpeakerId: String?) -> VerticalActiveSpeakerLayoutView {
            VerticalActiveSpeakerLayoutView(participants: participants, activeSpeakerId: activeSpeakerId)
        }

        @Test("Active speaker is included in main area when no screen share is active")
        func activeSpeakerIsProminentWithoutScreenShare() {
            let activeSpeakerId = "active"
            let participants = [
                UIParticipant(participant: makeMockParticipant(id: "other"), isPinned: false),
                UIParticipant(participant: makeMockParticipant(id: activeSpeakerId), isPinned: false),
            ]

            let sut = makeSUT(participants: participants, activeSpeakerId: activeSpeakerId)

            #expect(sut.mainAreaParticipants.map(\.id) == ["other", activeSpeakerId])
        }

        @Test("Active speaker is NOT included in main area when screen share is active")
        func activeSpeakerExcludedFromMainAreaDuringScreenShare() {
            let screenShareId = "ss"
            let activeSpeakerId = "active"
            let participants = [
                UIParticipant(
                    participant: makeMockParticipant(id: screenShareId, isScreenshare: true), isPinned: false),
                UIParticipant(participant: makeMockParticipant(id: activeSpeakerId), isPinned: false),
                UIParticipant(participant: makeMockParticipant(id: "other"), isPinned: false),
            ]

            let sut = makeSUT(participants: participants, activeSpeakerId: activeSpeakerId)

            let mainIds = sut.mainAreaParticipants.map(\.id)
            #expect(mainIds.contains(screenShareId))
            #expect(!mainIds.contains(activeSpeakerId))
        }

        @Test("Pinned participant IS included in main area when screen share is active")
        func pinnedParticipantIsProminentDuringScreenShare() {
            let screenShareId = "ss"
            let pinnedId = "pinned"
            let activeSpeakerId = "active"
            let participants = [
                UIParticipant(
                    participant: makeMockParticipant(id: screenShareId, isScreenshare: true), isPinned: false),
                UIParticipant(participant: makeMockParticipant(id: pinnedId), isPinned: true),
                UIParticipant(participant: makeMockParticipant(id: activeSpeakerId), isPinned: false),
            ]

            let sut = makeSUT(participants: participants, activeSpeakerId: activeSpeakerId)

            let mainIds = sut.mainAreaParticipants.map(\.id)
            #expect(mainIds.contains(screenShareId))
            #expect(mainIds.contains(pinnedId))
            #expect(!mainIds.contains(activeSpeakerId))
        }
    }
}
