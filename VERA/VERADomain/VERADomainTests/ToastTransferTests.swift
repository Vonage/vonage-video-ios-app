//
//  Created by Vonage on 14/10/2026.
//

import Testing
import VERADomain

@Suite("Toast notification value transfer")
struct ToastTransferTests {

    @Test("All toast modes preserve their accessibility names across tasks")
    func modesAcrossTasks() async {
        let modes: [ToastMode] = [.warning, .info, .failure, .success]
        let received = await Task.detached { modes }.value
        #expect(received == modes)
        #expect(received.map(\.accessibilityName) == ["warning", "info", "failure", "success"])
    }

    @Test("Toast snapshots preserve empty and Unicode messages and every mode across tasks")
    func snapshotsAcrossTasks() async {
        let modes: [ToastMode] = [.warning, .info, .failure, .success]
        let snapshots = modes.flatMap { mode in
            ["", "Meeting notification", "会議室 🚀"].map { ToastItem(message: $0, mode: mode) }
        }
        let received = await Task.detached { snapshots }.value
        #expect(received == snapshots)

        let optionalSnapshots: [ToastItem?] = [nil, snapshots[0], snapshots[11]]
        let optionalReceived = await Task.detached { optionalSnapshots }.value
        #expect(optionalReceived == optionalSnapshots)
    }
}
