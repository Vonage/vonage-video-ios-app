//
//  Created by Vonage on 2/4/26.
//

import Combine
import Foundation
import Testing
import VERADomain

@Suite("CallFacade types tests")
struct CallFacadeTypesTests {

    // MARK: - ParticipantsState

    @Test("ParticipantsState empty has no participants")
    func participantsStateEmpty() {
        let state = ParticipantsState.empty

        #expect(state.localParticipant == nil)
        #expect(state.participants.isEmpty)
        #expect(state.activeParticipantId == nil)
    }

    // MARK: - ArchivingState

    @Test("ArchivingState idle isArchiving returns false")
    func archivingStateIdleIsNotArchiving() {
        let state = ArchivingState.idle

        #expect(state.isArchiving == false)
    }

    @Test("ArchivingState archiving isArchiving returns true")
    func archivingStateArchivingIsArchiving() {
        let state = ArchivingState.archiving("archive-123")

        #expect(state.isArchiving == true)
    }

    @Test("ArchivingState equality for idle")
    func archivingStateIdleEquality() {
        #expect(ArchivingState.idle == ArchivingState.idle)
    }

    @Test("ArchivingState equality for archiving with same id")
    func archivingStateArchivingEqualitySameId() {
        #expect(ArchivingState.archiving("id1") == ArchivingState.archiving("id1"))
    }

    @Test("ArchivingState inequality for archiving with different id")
    func archivingStateArchivingInequalityDifferentId() {
        #expect(ArchivingState.archiving("id1") != ArchivingState.archiving("id2"))
    }

    @Test("ArchivingState inequality idle vs archiving")
    func archivingStateInequalityIdleVsArchiving() {
        #expect(ArchivingState.idle != ArchivingState.archiving("id1"))
    }

    // MARK: - CaptionsState

    @Test("CaptionsState disabled captionsEnabled returns false")
    func captionsStateDisabled() {
        let state = CaptionsState.disabled

        #expect(state.captionsEnabled == false)
    }

    @Test("CaptionsState enabled captionsEnabled returns true")
    func captionsStateEnabled() {
        let state = CaptionsState.enabled("captions-123")

        #expect(state.captionsEnabled == true)
    }

    @Test("CaptionsState equality for disabled")
    func captionsStateDisabledEquality() {
        #expect(CaptionsState.disabled == CaptionsState.disabled)
    }

    @Test("CaptionsState equality for enabled with same id")
    func captionsStateEnabledEqualitySameId() {
        #expect(CaptionsState.enabled("id1") == CaptionsState.enabled("id1"))
    }

    @Test("CaptionsState inequality for enabled with different id")
    func captionsStateEnabledInequalityDifferentId() {
        #expect(CaptionsState.enabled("id1") != CaptionsState.enabled("id2"))
    }

    // MARK: - NoiseSuppressionState

    @Test("NoiseSuppressionState enabled isEnabled returns true")
    func noiseSuppressionStateEnabled() {
        #expect(NoiseSuppressionState.enabled.isEnabled == true)
    }

    @Test("NoiseSuppressionState disabled isEnabled returns false")
    func noiseSuppressionStateDisabled() {
        #expect(NoiseSuppressionState.disabled.isEnabled == false)
    }

    @Test("NoiseSuppressionState idle isEnabled returns false")
    func noiseSuppressionStateIdle() {
        #expect(NoiseSuppressionState.idle.isEnabled == false)
    }

    @Test("NoiseSuppressionState equality")
    func noiseSuppressionStateEquality() {
        #expect(NoiseSuppressionState.enabled == NoiseSuppressionState.enabled)
        #expect(NoiseSuppressionState.disabled == NoiseSuppressionState.disabled)
        #expect(NoiseSuppressionState.idle == NoiseSuppressionState.idle)
        #expect(NoiseSuppressionState.enabled != NoiseSuppressionState.disabled)
        #expect(NoiseSuppressionState.enabled != NoiseSuppressionState.idle)
    }

    // MARK: - MeetingRoomLayout

    @Test("MeetingRoomLayout has expected cases")
    func meetingRoomLayoutCases() {
        let activeSpeaker = MeetingRoomLayout.activeSpeaker
        let grid = MeetingRoomLayout.grid

        // Verify they're distinct
        #expect(activeSpeaker != grid)
    }
}
