//
//  Created by Vonage on 25/06/2026.
//

import Foundation
import VERALogger

/// Factory responsible for creating the FileLogStrategy specifically configured for Vonage SDK logging.
public final class SDKFileLogStrategyFactory {
    private let logsDirectory: URL?
    public let defaultLogsDirectoryName = "VERASDKLogs"
    public let currentFileName = "sdk-log-current.log"
    public let defaultMaxFileCount = 5
    public let defaultMaxFileSize: UInt64 = 2 * 1024 * 1024
    public let archivePrefix = "sdk-log-"

    public init(logsDirectory: URL? = nil) {
        self.logsDirectory = logsDirectory
    }

    public func defaultDirectory(
        fileManager: FileManager = .default
    ) -> URL {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cachesDirectory.appendingPathComponent(
            self.defaultLogsDirectoryName, isDirectory: true)
    }

    public func makeStrategy() -> FileLogStrategy {
        let resolvedDirectory = self.logsDirectory ?? defaultDirectory()


        let logFileURL = resolvedDirectory.appendingPathComponent(
            self.currentFileName
        )

        return FileLogStrategy.Builder(fileURL: logFileURL)
            .logsDirectory(resolvedDirectory)
            .archivePrefix(self.archivePrefix)
            .maxFileSize(self.defaultMaxFileSize)
            .rotationPolicy(
                .rolling(maxFileCount: self.defaultMaxFileCount)
            )
            .minLevel(.verbose)
            .build()
    }
}
