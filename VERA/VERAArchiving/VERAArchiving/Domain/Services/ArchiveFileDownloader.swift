//
//  Created by Vonage on 18/10/26.
//

import Foundation

/// Downloads a remote archive file, such as a transcript zip, to local storage.
public protocol ArchiveFileDownloader {
    /// Downloads the file at `url`.
    ///
    /// - Parameters:
    ///   - url: Remote location of the file.
    ///   - fileName: Name to give the local copy, including its extension.
    /// - Returns: URL of the local copy.
    func download(from url: URL, fileName: String) async throws -> URL
}
