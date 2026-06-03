//
//  Created by Vonage on 31/05/2026.
//

import Foundation

public protocol BackgroundEffectsCacheProviding {
    func ensureCacheDirectory() throws
    func cachedFileURL(for assetName: String) throws -> URL
    func cachedFileExists(for assetName: String) throws -> Bool
}

public final class DefaultBackgroundEffectsCacheProvider: BackgroundEffectsCacheProviding {

    private let fileManager: FileManager
    private let cacheDirectory: URL?

    public init(
        fileManager: FileManager,
        pathComponent: String
    ) {
        self.fileManager = fileManager
        self.cacheDirectory =
            fileManager
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(pathComponent, isDirectory: true)
    }

    public func ensureCacheDirectory() throws {
        guard let cacheDirectory else {
            throw BackgroundEffectsCacheProviderError.cacheDirectoryUnavailable
        }

        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    public func cachedFileURL(for assetName: String) throws -> URL {
        guard let cacheDirectory else {
            throw BackgroundEffectsCacheProviderError.cacheDirectoryUnavailable
        }

        return cacheDirectory.appendingPathComponent("\(assetName).jpg")
    }

    public func cachedFileExists(for assetName: String) throws -> Bool {
        fileManager.fileExists(atPath: try cachedFileURL(for: assetName).path)
    }
}

public enum BackgroundEffectsCacheProviderError: Error {
    case cacheDirectoryUnavailable
}
