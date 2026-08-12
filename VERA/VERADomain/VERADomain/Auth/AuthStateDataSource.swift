//
//  Created by Vonage on 12/8/26.
//

import Combine
import Foundation

/// Provides a reactive stream of the current authentication state.
///
/// Implementations publish the current `AuthState` and emit updates
/// whenever the user's authentication status changes.
public protocol AuthStateDataSource {
    var authStatePublisher: AnyPublisher<AuthState, Never> { get }
}
