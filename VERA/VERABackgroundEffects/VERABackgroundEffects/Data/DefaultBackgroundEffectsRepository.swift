//
//  Created by Vonage on 31/05/2026.
//

import Foundation
import UIKit
import VERADomain

/// Loads built-in stock background images from the asset catalog and exports them
/// as JPEG files to a caches directory so the Vonage SDK can read them via file path.
public final class DefaultBackgroundEffectsRepository: BackgroundEffectsRepository {

    /// The asset names of the 8 stock background images in `BackgroundImages.xcassets`.
    static let stockAssetNames: [String] = [
        "bg_bookshelf_room",
        "bg_busy_room",
        "bg_dune_view",
        "bg_hogwarts",
        "bg_library",
        "bg_new_york",
        "bg_plane",
        "bg_white_room",
    ]

    private let bundle: Bundle
    private let cacheDirectory: URL
    private let fileManager: FileManager

    public init(
        bundle: Bundle = .init(for: DefaultBackgroundEffectsRepository.self),
        fileManager: FileManager = .default
    ) {
        self.bundle = bundle
        self.fileManager = fileManager
        self.cacheDirectory =
            fileManager
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("video_backgrounds", isDirectory: true)
    }

    public func availableBackgrounds() throws -> [VideoBackgroundItem] {
        try ensureCacheDirectory()
        return try Self.stockAssetNames.compactMap { assetName in
            try exportIfNeeded(assetName: assetName)
        }
    }

    // MARK: - Private

    private func ensureCacheDirectory() throws {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    private func exportIfNeeded(assetName: String) throws -> VideoBackgroundItem? {
        let cachedPath = cacheDirectory.appendingPathComponent("\(assetName).jpg")

        if fileManager.fileExists(atPath: cachedPath.path) {
            return VideoBackgroundItem(
                id: assetName,
                thumbnailResource: assetName,
                imagePath: cachedPath.path,
                isUserUploaded: false
            )
        }

        guard let image = UIImage(named: assetName, in: bundle, compatibleWith: nil),
            let imageData = image.jpegData(compressionQuality: 0.9)
        else { return nil }

        guard let croppedData = ImageCropUtils.centerCropToPortrait(imageData) else {
            return nil
        }

        try croppedData.write(to: cachedPath)

        return VideoBackgroundItem(
            id: assetName,
            thumbnailResource: assetName,
            imagePath: cachedPath.path,
            isUserUploaded: false
        )
    }
}
