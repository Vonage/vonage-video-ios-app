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

    private let directory: URL
    private let fileManager: FileManager

    public init(directory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.directory =
            directory
            ?? fileManager
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("user_backgrounds", isDirectory: true)
    }

    public func savedBackgrounds() throws -> [VideoBackgroundItem] {
        try ensureDirectory()

        guard fileManager.fileExists(atPath: directory.path) else { return [] }

        let files = try fileManager.contentsOfDirectory(
            at: directory,
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
        try ensureDirectory()

        guard remainingSlots > 0 else {
            throw UserBackgroundError.maxSlotsReached
        }

        let id = "user_bg_\(UUID().uuidString)"
        let filePath = directory.appendingPathComponent("\(id).jpg")

        guard let croppedData = ImageCropUtils.centerCropToPortrait(imageData) else {
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
        let filePath = directory.appendingPathComponent("\(id).jpg")
        if fileManager.fileExists(atPath: filePath.path) {
            try fileManager.removeItem(at: filePath)
        }
    }

    public var remainingSlots: Int {
        let currentCount = (try? savedBackgrounds().count) ?? 0
        return max(0, Self.maxUserBackgrounds - currentCount)
    }

    // MARK: - Private

    private func ensureDirectory() throws {
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
}

public enum UserBackgroundError: Error {
    case cropFailed
    case maxSlotsReached
}
