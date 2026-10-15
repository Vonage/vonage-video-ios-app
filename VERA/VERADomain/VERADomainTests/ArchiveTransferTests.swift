//
//  Created by Vonage on 14/10/2026.
//

import Foundation
import Testing
import VERADomain

@Suite("Recording archive value transfer")
struct ArchiveTransferTests {

    @Test("Archive arrays preserve statuses and metadata across tasks")
    func archiveSnapshots() async {
        let statuses: [ArchiveStatus] = [.stopped, .available, .failed]
        let archives = statuses.enumerated().map { index, status in
            Archive(
                id: UUID(), name: "recording-\(index)",
                createdAt: Date(timeIntervalSince1970: Double(index)), status: status,
                url: index == 1 ? URL(string: "https://example.com/recording.mp4") : nil,
                size: index * 1024, duration: index * 60)
        }
        for snapshot in [[], archives] {
            let received = await Task.detached { snapshot }.value
            #expect(received == snapshot)
        }
        for status in statuses {
            let received = await Task.detached { status }.value
            #expect(received == status)
        }
    }
}
