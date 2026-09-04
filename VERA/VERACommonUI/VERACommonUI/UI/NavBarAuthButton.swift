//
//  Created by Vonage on 12/8/26.
//

import SwiftUI
import VERADomain

private enum NavBarAuthButtonConstants {
    static let sheetHeight: CGFloat = 200
}

public struct NavBarAuthButton: View {
    private let authState: AuthState
    private let onLoginTapped: () -> Void
    private let onLogoutTapped: () async -> Void

    @State private var showAccountMenu = false
    @State private var isLoggingOut = false

    public init(
        authState: AuthState,
        onLoginTapped: @escaping () -> Void,
        onLogoutTapped: @escaping () async -> Void
    ) {
        self.authState = authState
        self.onLoginTapped = onLoginTapped
        self.onLogoutTapped = onLogoutTapped
    }

    public var body: some View {
        Button {
            switch authState {
            case .notAuthenticated:
                onLoginTapped()
            case .authenticated:
                showAccountMenu = true
            }
        } label: {
            switch authState {
            case .notAuthenticated:
                VERACommonUIAsset.Images.userSolid.swiftUIImage
                    .foregroundStyle(VERACommonUIAsset.SemanticColors.textPrimary.swiftUIColor)
                    .accessibilityLabel(Text("auth_sign_in", bundle: .module))
            case .authenticated:
                VERACommonUIAsset.Images.assignUserSolid.swiftUIImage
                    .foregroundStyle(VERACommonUIAsset.SemanticColors.primary.swiftUIColor)
                    .accessibilityLabel(Text("auth_signed_in", bundle: .module))
            }
        }
        .accessibilityIdentifier("auth-button")
        .sheet(isPresented: $showAccountMenu) {
            accountMenuView
                .presentationDetents([.height(NavBarAuthButtonConstants.sheetHeight)])
                .presentationDragIndicator(.visible)
        }
    }

    private var accountMenuView: some View {
        AuthAccountMenuView(
            userName: authState.user?.name,
            isLoggingOut: isLoggingOut
        ) {
            Task {
                isLoggingOut = true
                await onLogoutTapped()
                isLoggingOut = false
                showAccountMenu = false
            }
        }
    }
}
