//
//  Created by Vonage on 31/05/2026.
//

import Foundation
import Testing
import VERABackgroundEffects
import VERADomain

@Suite("DefaultVideoEffectRepository tests")
struct DefaultVideoEffectRepositoryTests {

    @Test("save and load round-trips blur effect")
    func saveAndLoadRoundTripsBlurEffect() {
        let defaults = makeIsolatedDefaults()
        let sut = DefaultVideoEffectRepository(defaults: defaults)

        sut.save(.blurHigh)
        let loaded = sut.load()

        #expect(loaded == .blurHigh)
    }

    @Test("save and load round-trips none")
    func saveAndLoadRoundTripsNone() {
        let defaults = makeIsolatedDefaults()
        let sut = DefaultVideoEffectRepository(defaults: defaults)

        sut.save(.none)
        let loaded = sut.load()

        #expect(loaded == .none)
    }

    @Test("save and load round-trips backgroundImage")
    func saveAndLoadRoundTripsBackgroundImage() throws {
        let defaults = makeIsolatedDefaults()
        let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("test_bg.jpg")
        try Data([0xFF]).write(to: tmpFile)
        defer { try? FileManager.default.removeItem(at: tmpFile) }

        let sut = DefaultVideoEffectRepository(defaults: defaults)

        sut.save(.backgroundImage(id: "test", imagePath: tmpFile.path))
        let loaded = sut.load()

        #expect(loaded == .backgroundImage(id: "test", imagePath: tmpFile.path))
    }

    @Test("load returns none when no data stored")
    func loadReturnsNoneWhenEmpty() {
        let defaults = makeIsolatedDefaults()
        let sut = DefaultVideoEffectRepository(defaults: defaults)

        let loaded = sut.load()

        #expect(loaded == .none)
    }

    @Test("load returns none when backgroundImage path is deleted")
    func loadReturnsNoneWhenPathDeleted() {
        let defaults = makeIsolatedDefaults()
        let sut = DefaultVideoEffectRepository(defaults: defaults)

        sut.save(.backgroundImage(id: "gone", imagePath: "/nonexistent/path.jpg"))
        let loaded = sut.load()

        #expect(loaded == .none)
    }

    @Test("load auto-repairs UserDefaults when backgroundImage path is deleted")
    func loadAutoRepairsWhenPathDeleted() {
        let defaults = makeIsolatedDefaults()
        let sut = DefaultVideoEffectRepository(defaults: defaults)

        sut.save(.backgroundImage(id: "gone", imagePath: "/nonexistent/path.jpg"))
        _ = sut.load()

        // Second load should still return .none (auto-repaired in UserDefaults)
        let secondLoad = sut.load()
        #expect(secondLoad == .none)
    }

    // MARK: - Helpers

    private func makeIsolatedDefaults() -> UserDefaults {
        let suiteName = "test.videoeffect.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
