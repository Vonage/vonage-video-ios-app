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
    func saveAndLoadRoundTripsBlurEffect() throws {
        let defaults = makeIsolatedDefaults()
        let sut = DefaultVideoEffectRepository(defaults: defaults)

        try sut.save(.blurHigh)
        let loaded = sut.load()

        #expect(loaded == .blurHigh)
    }

    @Test("save and load round-trips none")
    func saveAndLoadRoundTripsNone() throws {
        let defaults = makeIsolatedDefaults()
        let sut = DefaultVideoEffectRepository(defaults: defaults)

        try sut.save(.none)
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

        try sut.save(.backgroundImage(id: "test", imagePath: tmpFile.path))
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
    func loadReturnsNoneWhenPathDeleted() throws {
        let defaults = makeIsolatedDefaults()
        let sut = DefaultVideoEffectRepository(defaults: defaults)

        try sut.save(.backgroundImage(id: "gone", imagePath: "/nonexistent/path.jpg"))
        let loaded = sut.load()

        #expect(loaded == .none)
    }

    @Test("load does not overwrite backgroundImage when path is deleted")
    func loadDoesNotOverwriteBackgroundImageWhenPathDeleted() throws {
        let defaults = makeIsolatedDefaults()
        let tmpFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_bg_\(UUID().uuidString).jpg")
        defer { try? FileManager.default.removeItem(at: tmpFile) }

        let sut = DefaultVideoEffectRepository(defaults: defaults)
        let effect = VideoEffect.backgroundImage(id: "gone", imagePath: tmpFile.path)

        try sut.save(effect)
        #expect(sut.load() == .none)

        try Data([0xFF]).write(to: tmpFile)
        #expect(sut.load() == effect)
    }

    // MARK: - Helpers

    private func makeIsolatedDefaults() -> UserDefaults {
        let suiteName = "test.videoeffect.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
