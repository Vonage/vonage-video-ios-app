//
//  Created by Vonage on 31/05/2026.
//

import Foundation

public protocol BackgroundEffectsStorageProviding {
    func ensureDirectory() throws
    func fileURL(for id: String) throws -> URL
    func fileExists(for id: String) throws -> Bool
    func contentsOfDirectory(
        includingPropertiesForKeys keys: [URLResourceKey],
        options: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL]
    func removeFile(for id: String) throws
}

public final class DefaultBackgroundEffectsStorageProvider: BackgroundEffectsStorageProviding {

    private let fileManager: FileManager
    private let directory: URL?

    public init(
        fileManager: FileManager,
        searchPathDirectory: FileManager.SearchPathDirectory,
        pathComponent: String
    ) {
        self.fileManager = fileManager
        self.directory =
            fileManager
            .urls(for: searchPathDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(pathComponent, isDirectory: true)
    }

    public func ensureDirectory() throws {
        guard let directory else {
            throw BackgroundEffectsStorageProviderError.directoryUnavailable
        }

        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    public func fileURL(for id: String) throws -> URL {
        guard let directory else {
            throw BackgroundEffectsStorageProviderError.directoryUnavailable
        }

        return directory.appendingPathComponent("\(id).jpg")
    }

    public func fileExists(for id: String) throws -> Bool {
        fileManager.fileExists(atPath: try fileURL(for: id).path)
    }

    public func contentsOfDirectory(
        includingPropertiesForKeys keys: [URLResourceKey],
        options: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL] {
        guard let directory else {
            throw BackgroundEffectsStorageProviderError.directoryUnavailable
        }

        return try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: keys,
            options: options
        )
    }

    public func removeFile(for id: String) throws {
        try fileManager.removeItem(at: try fileURL(for: id))
    }
}

public enum BackgroundEffectsStorageProviderError: Error {
    case directoryUnavailable
}
