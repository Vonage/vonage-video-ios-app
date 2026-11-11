//
//  Created by Vonage on 14/10/2026.
//

import Combine
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

    @Test("Unavailable noise suppression remains disabled when enablement is requested")
    func unavailableNoiseSuppressionStaysDisabled() {
        let sut = NullNoiseSuppressionStatusDataSource()
        var states: [NoiseSuppressionState] = []
        let initial = sut.noiseSuppressionState.sink { states.append($0) }
        sut.set(state: .enabled)
        let afterEnablement = sut.noiseSuppressionState.sink { states.append($0) }
        sut.set(state: .idle)
        let afterReset = sut.noiseSuppressionState.sink { states.append($0) }
        #expect(states == [.disabled, .disabled, .disabled])
        withExtendedLifetime((initial, afterEnablement, afterReset)) {}
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
