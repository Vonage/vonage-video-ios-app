//
//  Created by Vonage on 31/05/2026.
//

import Foundation
import Testing
import VERABackgroundEffects
import VERADomain

@Suite("DefaultUserBackgroundRepository tests")
struct DefaultUserBackgroundRepositoryTests {

    @Test("save stores image and returns item")
    func saveStoresImageAndReturnsItem() throws {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let sut = DefaultUserBackgroundRepository(directory: dir)

        let imageData = makeMinimalJPEGData()
        let item = try sut.save(imageData)

        #expect(item.isUserUploaded)
        #expect(FileManager.default.fileExists(atPath: item.imagePath))
    }

    @Test("savedBackgrounds returns saved items")
    func savedBackgroundsReturnsSavedItems() throws {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let sut = DefaultUserBackgroundRepository(directory: dir)

        let imageData = makeMinimalJPEGData()
        _ = try sut.save(imageData)
        let items = try sut.savedBackgrounds()

        #expect(items.count == 1)
        #expect(items[0].isUserUploaded)
    }

    @Test("delete removes file and background")
    func deleteRemovesFileAndBackground() throws {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let sut = DefaultUserBackgroundRepository(directory: dir)

        let imageData = makeMinimalJPEGData()
        let item = try sut.save(imageData)
        try sut.delete(item.id)

        let items = try sut.savedBackgrounds()
        #expect(items.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: item.imagePath))
    }

    @Test("remainingSlots accounts for saved items")
    func remainingSlotsAccountsForSavedItems() throws {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let sut = DefaultUserBackgroundRepository(directory: dir)

        let initialSlots = sut.remainingSlots
        let imageData = makeMinimalJPEGData()
        _ = try sut.save(imageData)

        #expect(sut.remainingSlots == initialSlots - 1)
    }

    @Test("save throws maxSlotsReached when limit exceeded")
    func saveThrowsMaxSlotsReached() throws {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let sut = DefaultUserBackgroundRepository(directory: dir)

        let imageData = makeMinimalJPEGData()
        for _ in 0..<DefaultUserBackgroundRepository.maxUserBackgrounds {
            _ = try sut.save(imageData)
        }

        #expect(throws: (any Error).self) {
            try sut.save(imageData)
        }
    }

    // MARK: - Helpers

    private func makeTempDirectory() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_user_bg_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func makeMinimalJPEGData() -> Data {
        // Minimal valid JPEG header
        Data([
            0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x00,
            0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xD9,
        ])
    }
}
