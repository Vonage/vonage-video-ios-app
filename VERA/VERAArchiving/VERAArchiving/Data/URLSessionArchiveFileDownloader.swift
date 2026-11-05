//
//  Created by Vonage on 18/10/26.
//

import Foundation

/// Downloads archive files with `URLSession` into the temporary directory.
///
/// Archive URLs are pre-signed storage links, so requests are sent without the app's API headers.
public struct URLSessionArchiveFileDownloader: ArchiveFileDownloader {

    public enum Error: Swift.Error {
        case httpError(statusCode: Int)
    }

    private let session: URLSession
    private let fileManager: FileManager

    public init(session: URLSession = .shared, fileManager: FileManager = .default) {
        self.session = session
        self.fileManager = fileManager
    }

    public func download(from url: URL, fileName: String) async throws -> URL {
        let (temporaryURL, response) = try await session.download(from: url)

        if let httpResponse = response as? HTTPURLResponse,
            !(200..<300).contains(httpResponse.statusCode)
        {
            try? fileManager.removeItem(at: temporaryURL)
            throw Error.httpError(statusCode: httpResponse.statusCode)
        }

        // Downloading the same file again replaces the earlier copy.
        let destination = fileManager.temporaryDirectory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: destination)
        try fileManager.moveItem(at: temporaryURL, to: destination)
        return destination
    }
}
