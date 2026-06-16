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
    private let storageProvider: BackgroundEffectsStorageProviding

    public init(
        bundle: Bundle,
        storageProvider: BackgroundEffectsStorageProviding
    ) {
        self.bundle = bundle
        self.storageProvider = storageProvider
    }

    public func availableBackgrounds() throws -> [VideoBackgroundItem] {
        try storageProvider.ensureDirectory()
        return try Self.stockAssetNames.map { assetName in
            try exportIfNeeded(assetName: assetName)
        }
    }

    // MARK: - Private

    private func exportIfNeeded(assetName: String) throws -> VideoBackgroundItem {
        let cachedPath = try storageProvider.fileURL(for: assetName)

        if try storageProvider.fileExists(for: assetName) {
            return VideoBackgroundItem(
                id: assetName,
                thumbnailResource: assetName,
                imagePath: cachedPath.path,
                isUserUploaded: false
            )
        }

        guard let image = UIImage(named: assetName, in: bundle, compatibleWith: nil) else {
            throw BackgroundEffectsRepositoryError.assetNotFound(assetName: assetName)
        }

        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw BackgroundEffectsRepositoryError.jpegEncodingFailed(assetName: assetName)
        }

        let croppedData: Data
        do {
            croppedData = try ImageCropUtils.centerCropToPortrait(imageData)
        } catch {
            throw BackgroundEffectsRepositoryError.cropFailed(assetName: assetName)
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

public enum BackgroundEffectsRepositoryError: Error, Equatable {
    case assetNotFound(assetName: String)
    case jpegEncodingFailed(assetName: String)
    case cropFailed(assetName: String)
}
