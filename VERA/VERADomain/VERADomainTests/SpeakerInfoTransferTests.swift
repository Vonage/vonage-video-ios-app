//
//  Created by Vonage on 14/10/2026.
//

import Testing
import VERADomain

@Suite("Speaker snapshot value transfer")
struct SpeakerInfoTransferTests {

    @Test("Speaker arrays preserve identifiers, levels and microphone flags across tasks")
    func speakerSnapshotsAcrossTasks() async {
        let speakers = [
            SpeakerInfo(id: "silent", isMicEnabled: true),
            SpeakerInfo(id: "speaking", audioLevel: 0.25, isMicEnabled: true),
            SpeakerInfo(id: "muted", audioLevel: 1.0, isMicEnabled: false),
        ]
        for snapshot in [[], speakers] {
            let received = await Task.detached { snapshot }.value
            #expect(received.map(\.id) == snapshot.map(\.id))
            #expect(received.map(\.audioLevel) == snapshot.map(\.audioLevel))
            #expect(received.map(\.isMicEnabled) == snapshot.map(\.isMicEnabled))
        }
    }
}
