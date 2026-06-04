//
//  Created by Vonage on 31/05/2026.
//

import Combine
import Foundation
import Testing
import UIKit
import VERABackgroundEffects
import VERADomain

@Suite("DefaultUserBackgroundRepository tests")
struct DefaultUserBackgroundRepositoryTests {

    @Test("save stores image and returns item")
    func saveStoresImageAndReturnsItem() throws {
        let (sut, directory) = makeSUT()
        defer { try? FileManager.default.removeItem(at: directory) }

        let imageData = makeMinimalJPEGData()
        let item = try sut.save(imageData)

        #expect(item.isUserUploaded)
        #expect(FileManager.default.fileExists(atPath: item.imagePath))
    }

    @Test("savedBackgrounds returns saved items")
    func savedBackgroundsReturnsSavedItems() throws {
        let (sut, directory) = makeSUT()
        defer { try? FileManager.default.removeItem(at: directory) }

        let imageData = makeMinimalJPEGData()
        _ = try sut.save(imageData)
        let items = try sut.savedBackgrounds()

        #expect(items.count == 1)
        #expect(items[0].isUserUploaded)
    }

    @Test("delete removes file and background")
    func deleteRemovesFileAndBackground() throws {
        let (sut, directory) = makeSUT()
        defer { try? FileManager.default.removeItem(at: directory) }

        let imageData = makeMinimalJPEGData()
        let item = try sut.save(imageData)
        try sut.delete(item.id)

        let items = try sut.savedBackgrounds()
        #expect(items.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: item.imagePath))
    }

    @Test("remainingSlotsPublisher emits initial slots")
    func remainingSlotsPublisherEmitsInitialSlots() throws {
        let (sut, directory) = makeSUT()
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(remainingSlots(from: sut) == DefaultUserBackgroundRepository.maxUserBackgrounds)
    }

    @Test("remainingSlotsPublisher emits after save")
    func remainingSlotsPublisherEmitsAfterSave() throws {
        let (sut, directory) = makeSUT()
        defer { try? FileManager.default.removeItem(at: directory) }

        let imageData = makeMinimalJPEGData()
        _ = try sut.save(imageData)

        #expect(remainingSlots(from: sut) == DefaultUserBackgroundRepository.maxUserBackgrounds - 1)
    }

    @Test("remainingSlotsPublisher emits after delete")
    func remainingSlotsPublisherEmitsAfterDelete() throws {
        let (sut, directory) = makeSUT()
        defer { try? FileManager.default.removeItem(at: directory) }

        let imageData = makeMinimalJPEGData()
        let item = try sut.save(imageData)
        try sut.delete(item.id)

        #expect(remainingSlots(from: sut) == DefaultUserBackgroundRepository.maxUserBackgrounds)
    }

    @Test("save throws maxSlotsReached when limit exceeded")
    func saveThrowsMaxSlotsReached() throws {
        let (sut, directory) = makeSUT()
        defer { try? FileManager.default.removeItem(at: directory) }

        let imageData = makeMinimalJPEGData()
        for _ in 0..<DefaultUserBackgroundRepository.maxUserBackgrounds {
            _ = try sut.save(imageData)
        }

        #expect(throws: (any Error).self) {
            try sut.save(imageData)
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> (DefaultUserBackgroundRepository, URL) {
        let pathComponent = "test_user_bg_\(UUID().uuidString)"
        let directory = cachesDirectory.appendingPathComponent(pathComponent, isDirectory: true)
        let storageProvider = DefaultBackgroundEffectsStorageProvider(
            fileManager: .default,
            searchPathDirectory: .cachesDirectory,
            pathComponent: pathComponent
        )
        return (DefaultUserBackgroundRepository(storageProvider: storageProvider), directory)
    }

    private var cachesDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    private func makeMinimalJPEGData() -> Data {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.jpegData(compressionQuality: 0.8)!
    }

    private func remainingSlots(from sut: DefaultUserBackgroundRepository) -> Int {
        var remainingSlots = -1
        let cancellable = sut.remainingSlotsPublisher.sink { remainingSlots = $0 }
        cancellable.cancel()
        return remainingSlots
    }
}
