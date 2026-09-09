//
//  Created by Vonage on 9/9/26.
//

import Foundation

/// Resolves the API base URL used by the app.
enum BaseURLResolver {

    /// Resolves the API base URL, preferring the value injected via `app-config.json`
    /// (`AppConfig.baseApiUrl`) and falling back to the build-time environment constant
    /// when the configured value is empty or not a valid URL.
    ///
    /// - Parameters:
    ///   - configuredURLString: The URL string coming from the app configuration.
    ///   - fallback: The URL to use when `configuredURLString` is empty or invalid.
    /// - Returns: A valid `URL` from `configuredURLString`, otherwise `fallback`.
    static func resolve(configuredURLString: String, fallback: URL) -> URL {
        if !configuredURLString.isEmpty,
            let url = URL(string: configuredURLString)
        {
            return url
        }
        return fallback
    }
}
