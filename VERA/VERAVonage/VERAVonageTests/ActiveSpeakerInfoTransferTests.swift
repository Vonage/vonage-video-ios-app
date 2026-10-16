//
//  Created by Vonage on 14/10/2026.
//

import Testing
import VERADomain
import VERAVonage

@Suite("Active speaker snapshot value transfer")
struct ActiveSpeakerInfoTransferTests {

    @Test("Empty and populated active speaker values survive task transfer")
    func activeSpeakerSnapshotsAcrossTasks() async {
        let snapshots = [
            ActiveSpeakerInfo.none,
            ActiveSpeakerInfo(participantId: "speaker", audioLevel: 0.75),
        ]
        let received = await Task.detached { snapshots }.value
        #expect(received == snapshots)
        #expect(received[0].participantId == nil)
        #expect(received[0].audioLevel == 0)
    }

    @Test("Speaker snapshots retain their identity and level when converted after transfer")
    func speakerConversionAfterTransfer() async {
        let speaker = SpeakerInfo(id: "speaker", audioLevel: 0.5, isMicEnabled: false)
        let received = await Task.detached { speaker.activeSpeakerInfo }.value
        #expect(received.participantId == speaker.id)
        #expect(received.audioLevel == speaker.audioLevel)
    }
}
