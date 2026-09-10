//
//  Created by Vonage on 12/8/26.
//

import Foundation

/// Provides the current valid access token for authenticated HTTP requests.
///
/// Used by the HTTP client layer to attach Bearer tokens without
/// depending on any specific identity provider SDK directly.
public protocol TokenProvider: Sendable {
    /// Returns the current valid access token, refreshing if expired.
    /// Returns `nil` if the user is not authenticated.
    func token() async -> String?
}
