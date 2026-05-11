//
//  Created by Vonage on 11/5/26.
//

import Combine
import Foundation
import Testing
import VERABackgroundEffects
import VERADomain
import VERASettings

@testable import VERA

// `BackgroundEffectsPreferencesAdapter` is defined in VERA inside
// `#if BACKGROUND_EFFECTS_ENABLED && SETTINGS_ENABLED`. The VERATests target
// does not inherit those compilation conditions, so we don't gate the test
// suite the same way — `@testable import VERA` exposes the symbol because the
// VERA target itself is built with both flags. If either flag is ever
// disabled at the VERA target level this file will fail to compile, which is
// the right signal.
@Suite("BackgroundEffectsPreferencesAdapter tests")
struct BackgroundEffectsPreferencesAdapterTests {

    @Test
    func defaultsExposeVonageAndFast() {
        let repository = StubPreferencesRepository(initial: .default)

        let sut = BackgroundEffectsPreferencesAdapter(repository: repository)

        #expect(sut.getProvider() == .vonage)
        #expect(sut.getVisionQuality() == .fast)
    }

    @Test
    func initialEmissionPopulatesAppleVisionPreferences() {
        let prefs = PublisherSettingsPreferences(
            backgroundProvider: .appleVision,
            appleVisionQuality: .accurate
        )
        let repository = StubPreferencesRepository(initial: prefs)

        let sut = BackgroundEffectsPreferencesAdapter(repository: repository)

        #expect(sut.getProvider() == .appleVision)
        #expect(sut.getVisionQuality() == .accurate)
    }

    @Test
    func subsequentEmissionUpdatesAccessors() {
        let repository = StubPreferencesRepository(initial: .default)
        let sut = BackgroundEffectsPreferencesAdapter(repository: repository)

        // Sanity: defaults
        #expect(sut.getProvider() == .vonage)

        // Repository emits a new value — adapter updates synchronously
        // because the underlying publisher is a `CurrentValueSubject` that
        // calls subscribers inline.
        repository.send(
            PublisherSettingsPreferences(
                backgroundProvider: .appleVision,
                appleVisionQuality: .balanced
            ))

        #expect(sut.getProvider() == .appleVision)
        #expect(sut.getVisionQuality() == .balanced)
    }

    @Test
    func performanceHUDEnabledIsForwardedToTracker() async {
        let tracker = TransformPerformanceTracker.shared
        // Adapter init pushes the initial preferences value into the tracker;
        // verify with both true and false to ensure the wire is live.
        let on = PublisherSettingsPreferences(performanceHUDEnabled: true)
        let off = PublisherSettingsPreferences(performanceHUDEnabled: false)

        let repository = StubPreferencesRepository(initial: on)
        _ = BackgroundEffectsPreferencesAdapter(repository: repository)
        await waitForMainHop()
        #expect(tracker.isVisible == true)

        repository.send(off)
        await waitForMainHop()
        #expect(tracker.isVisible == false)
    }

    // MARK: - Helpers

    private func waitForMainHop() async {
        try? await Task.sleep(nanoseconds: 50_000_000)
    }
}

// MARK: - Test doubles

/// `PublisherSettingsRepository` whose initial value is delivered
/// synchronously on subscribe (matches the production `CurrentValueSubject`-
/// backed implementation) and lets tests push subsequent values.
private final class StubPreferencesRepository: PublisherSettingsRepository, @unchecked Sendable {

    private let subject: CurrentValueSubject<PublisherSettingsPreferences, Never>

    var preferencesPublisher: AnyPublisher<PublisherSettingsPreferences, Never> {
        subject.eraseToAnyPublisher()
    }

    init(initial: PublisherSettingsPreferences) {
        self.subject = CurrentValueSubject(initial)
    }

    func send(_ value: PublisherSettingsPreferences) {
        subject.send(value)
    }

    func getPreferences() async -> PublisherSettingsPreferences { subject.value }
    func save(_ preferences: PublisherSettingsPreferences) async throws { subject.send(preferences) }
    func reset() async { subject.send(.default) }
}
