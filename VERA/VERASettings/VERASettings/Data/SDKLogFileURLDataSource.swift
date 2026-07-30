//
//  Created by Vonage on 23/06/2026.
//

import Foundation

/// A ``LogFileURLDataSource`` implementation that retrieves log file URLs
/// from a closure.
///
/// This adapter bridges the Settings module's domain protocol with the
/// ``SDKLoggingService`` (in `VERAVonage`), which exposes a `getLogFileURLs()`
/// method. The composition root provides the closure at initialization.
public final class SDKLogFileURLDataSource: LogFileURLDataSource {

    private let provider: () -> [URL]

    /// Creates a data source backed by the given provider closure.
    ///
    /// - Parameter provider: A closure that returns the current log file URLs.
    ///   Typically `sdkLoggingService.getLogFileURLs`.
    public init(provider: @escaping () -> [URL]) {
        self.provider = provider
    }

    public func getLogFileURLs() -> [URL] {
        provider()
    }
}
