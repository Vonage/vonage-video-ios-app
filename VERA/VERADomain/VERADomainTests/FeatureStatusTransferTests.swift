//
//  Created by Vonage on 14/10/2026.
//

import Testing
import VERADomain

@Suite("Feature status value transfer")
struct FeatureStatusTransferTests {

    @Test("Recording states retain their values across tasks")
    func archivingAcrossTasks() async {
        let states: [ArchivingState] = [.idle, .archiving("archive-id")]
        for state in states {
            let received = await Task.detached { state }.value
            #expect(received == state)
        }
    }

    @Test("Captions states retain their optional identifiers across tasks")
    func captionsAcrossTasks() async {
        let states: [CaptionsState] = [.disabled, .enabled(nil), .enabled("captions-id")]
        for state in states {
            let received = await Task.detached { state }.value
            #expect(received == state)
        }
    }

    @Test("Noise suppression states retain their values across tasks")
    func noiseAcrossTasks() async {
        let states: [NoiseSuppressionState] = [.idle, .enabled, .disabled]
        for state in states {
            let received = await Task.detached { state }.value
            #expect(received == state)
        }
    }
}
