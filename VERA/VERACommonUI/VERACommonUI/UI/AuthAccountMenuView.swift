//
//  Created by Vonage on 13/8/26.
//

import SwiftUI
import VERADomain

private enum AuthAccountMenuViewConstants {
    static let contentSpacing: CGFloat = 16
    static let buttonHorizontalPadding: CGFloat = 32
}

/// Displays the authenticated user's account menu with their name and a sign-out button.
public struct AuthAccountMenuView: View {
    private let userName: String?
    private let isLoggingOut: Bool
    private let onSignOut: () -> Void

    public init(
        userName: String?,
        isLoggingOut: Bool = false,
        onSignOut: @escaping () -> Void
    ) {
        self.userName = userName
        self.isLoggingOut = isLoggingOut
        self.onSignOut = onSignOut
    }

    public var body: some View {
        VStack(spacing: AuthAccountMenuViewConstants.contentSpacing) {
            if let name = userName {
                Text(name)
                    .adaptiveFont(.headline)
                    .foregroundStyle(VERACommonUIAsset.SemanticColors.textPrimary.swiftUIColor)
                    .accessibilityIdentifier("auth-account-name")
            }

            OutlinedButton(
                text: Text("auth_sign_out", bundle: .module),
                color: VERACommonUIAsset.SemanticColors.error.swiftUIColor,
                isDisabled: isLoggingOut
            ) {
                onSignOut()
            }
            .accessibilityIdentifier("auth-sign-out-button")
            .padding(.horizontal, AuthAccountMenuViewConstants.buttonHorizontalPadding)
        }
        .padding()
        .accessibilityIdentifier("auth-account-menu")
    }
}
