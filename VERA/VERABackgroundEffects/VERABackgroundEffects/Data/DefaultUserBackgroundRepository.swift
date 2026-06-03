//
//  Created by Vonage on 31/05/2026.
//

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

    public init(storageProvider: BackgroundEffectsStorageProviding) {
        self.storageProvider = storageProvider
    }

    public func savedBackgrounds() throws -> [VideoBackgroundItem] {
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

    public func save(_ imageData: Data) throws -> VideoBackgroundItem {
        try storageProvider.ensureDirectory()

        guard remainingSlots > 0 else {
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
        }
    }

    public var remainingSlots: Int {
        let currentCount = (try? savedBackgrounds().count) ?? 0
        return max(0, Self.maxUserBackgrounds - currentCount)
    }

    // MARK: - Private
}

public enum UserBackgroundError: Error {
    case cropFailed
    case maxSlotsReached
}
