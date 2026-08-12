//
//  Created by Vonage on 12/8/26.
//

import SwiftUI
import VERADomain

/// Factory for creating the OKTA feature components.
///
/// Follows the Wireframe/Factory pattern used across all VERA feature modules.
/// The factory knows about all layers (Domain, Data, UI) and wires them together.
public enum OKTAFactory {

    /// Creates the `SignInView` sheet with OKTA as the sole provider.
    /// - Parameter onProviderSelected: Called when the user selects OKTA to sign in.
    /// - Returns: A view suitable for presentation in a `.sheet`.
    @MainActor
    public static func makeSignInView(
        providers: [IDProvider],
        onProviderSelected: @escaping (IDProvider) async throws -> Void
    ) -> some View {
        SignInView(providers: providers, onProviderSelected: onProviderSelected)
    }
}
