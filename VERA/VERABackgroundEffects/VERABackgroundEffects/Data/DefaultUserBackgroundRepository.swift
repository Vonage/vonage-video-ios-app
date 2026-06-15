//
//  Created by Vonage on 31/05/2026.
//

import Combine
import Foundation
import UIKit
import VERADomain

/// Manages user-uploaded background images on disk.
///
/// Images are saved as portrait-cropped JPEGs in a dedicated directory under the app's
/// documents folder, persisting across app launches.
public final class DefaultUserBackgroundRepository: UserBackgroundRepository {

    public static let maxUserBackgrounds = 10

    private let storageProvider: BackgroundEffectsStorageProviding
    private let remainingSlotsSubject: CurrentValueSubject<Int, Never>

    public init(storageProvider: BackgroundEffectsStorageProviding) {
        self.storageProvider = storageProvider
        remainingSlotsSubject = CurrentValueSubject(Self.remainingSlots(using: storageProvider))
    }

    public var remainingSlotsPublisher: AnyPublisher<Int, Never> {
        remainingSlotsSubject.eraseToAnyPublisher()
    }

    public func savedBackgrounds() throws -> [VideoBackgroundItem] {
        try Self.savedBackgrounds(using: storageProvider)
    }

    public func save(_ imageData: Data) throws -> VideoBackgroundItem {
        try storageProvider.ensureDirectory()

        guard currentRemainingSlots > 0 else {
            throw UserBackgroundError.maxSlotsReached
        }

        let id = "user_bg_\(UUID().uuidString)"
        let filePath = try storageProvider.fileURL(for: id)

        let croppedData: Data
        do {
            croppedData = try ImageCropUtils.centerCropToPortrait(imageData)
        } catch {
            throw UserBackgroundError.cropFailed
        }

        try croppedData.write(to: filePath)
        publishRemainingSlots()

        return VideoBackgroundItem(
            id: id,
            thumbnailResource: nil,
            imagePath: filePath.path,
            isUserUploaded: true
        )
    }

    public func delete(_ id: String) throws {
        if try storageProvider.fileExists(for: id) {
            try storageProvider.removeFile(for: id)
            publishRemainingSlots()
        }
    }

    // MARK: - Private

    private var currentRemainingSlots: Int {
        Self.remainingSlots(using: storageProvider)
    }

    private func publishRemainingSlots() {
        remainingSlotsSubject.send(currentRemainingSlots)
    }

    private static func remainingSlots(using storageProvider: BackgroundEffectsStorageProviding) -> Int {
        let currentCount = (try? savedBackgrounds(using: storageProvider).count) ?? 0
        return max(0, maxUserBackgrounds - currentCount)
    }

    private static func savedBackgrounds(
        using storageProvider: BackgroundEffectsStorageProviding
    ) throws -> [VideoBackgroundItem] {
        try storageProvider.ensureDirectory()

        let files = try storageProvider.contentsOfDirectory(
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )

        return
            files
            .filter { $0.pathExtension.lowercased() == "jpg" }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return date1 < date2
            }
            .map { url in
                let id = url.deletingPathExtension().lastPathComponent
                return VideoBackgroundItem(
                    id: id,
                    thumbnailResource: nil,
                    imagePath: url.path,
                    isUserUploaded: true
                )
            }
    }
}

public enum UserBackgroundError: Error {
    case cropFailed
    case maxSlotsReached
}
