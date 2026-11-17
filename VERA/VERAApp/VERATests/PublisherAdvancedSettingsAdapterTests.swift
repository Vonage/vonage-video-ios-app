//
//  Created by Vonage on 21/10/26.
//

// The test target does not inherit the app's compilation conditions, so gate on the module instead.
#if canImport(VERASettings)
    import Combine
    import Foundation
    import Testing
    import VERASettings

    @testable import VERA

    @Suite("Publisher advanced settings adapter")
    @MainActor
    struct PublisherAdvancedSettingsAdapterTests {
        @Test("Only publisher setting changes reset the camera preview")
        func onlyPublisherChangesTriggerReset() async {
            let sut = PublisherAdvancedSettingsAdapter()
            let preferences = CurrentValueSubject<PublisherSettingsPreferences, Never>(.default)
            var resets = 0
            sut.onChange = { resets += 1 }
            sut.setup(with: preferences.eraseToAnyPublisher())

            preferences.value.captionsTranslationLanguage = "es-ES"
            preferences.value.statsOverlayEnabled.toggle()
            preferences.value.opusDtxEnabled.toggle()
            // The adapter delivers on the main queue; let it drain.
            await Task.yield()
            await withCheckedContinuation { continuation in
                DispatchQueue.main.async { continuation.resume() }
            }

            #expect(resets == 1)
            #expect(sut.get()?.opusDtxEnabled == PublisherSettingsPreferences.default.opusDtxEnabled.toggled)
        }
    }

    extension Bool {
        fileprivate var toggled: Bool { !self }
    }
#endif
