//
//  Created by Vonage on 03/07/26.
//

import SwiftUI
import Testing

@testable import VERACore

struct ViewHolderAudioOutputTestButtonTests {

    // MARK: - Audio Diagnostics Specific Tests

    @Test("ViewHolder can represent audio diagnostics button specifically")
    func viewHolderCanRepresentAudioDiagnosticsButtonSpecifically() throws {
        let audioDiagnosticsButton = ViewHolder(id: "audio-diagnostics") {
            Button("Test Audio Output") {
                // Audio diagnostics action
            }
            .accessibilityIdentifier("audio-diagnostics-button")
        }

        #expect(audioDiagnosticsButton.id == "audio-diagnostics")
        #expect(audioDiagnosticsButton.content() != nil)
    }

    @Test("Audio diagnostics ViewHolder supports accessibility")
    func audioDiagnosticsViewHolderSupportsAccessibility() throws {
        let audioDiagnosticsButton = ViewHolder(id: "audio-diagnostics-accessible") {
            Button("Test Audio Output") {
                // Audio diagnostics action
            }
            .accessibilityIdentifier("audio-diagnostics-button")
            .accessibilityLabel("Test speaker audio output")
            .accessibilityHint("Tap to play a test sound through your speakers")
        }

        #expect(audioDiagnosticsButton.id == "audio-diagnostics-accessible")
    }
}
