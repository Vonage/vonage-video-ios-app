//
//  Created by Vonage on 14/10/2026.
//

import Foundation
import Testing
import VERADomain

@Suite("Caption snapshot value transfer")
struct CaptionTransferTests {

    @Test("Caption arrays preserve speaker, text, ownership and timestamps across tasks")
    func snapshotsAcrossTasks() async {
        let remote = CaptionItem(
            id: "remote-caption", speakerName: "Ada", text: "Hello", isMe: false,
            timestamp: Date(timeIntervalSince1970: 42))
        let local = CaptionItem(
            id: "local-caption", speakerName: "Local", text: "Hello, 世界", isMe: true,
            timestamp: Date(timeIntervalSince1970: 43))
        let snapshots: [[CaptionItem]] = [[], [remote], [remote, local]]

        for snapshot in snapshots {
            let received = await Task.detached { snapshot }.value
            #expect(received == snapshot)
        }
    }
}
