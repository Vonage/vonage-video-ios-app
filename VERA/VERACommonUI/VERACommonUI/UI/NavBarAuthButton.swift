//
//  Created by Vonage on 12/8/26.
//

import SwiftUI
import VERADomain

private enum NavBarAuthButtonConstants {
    static let sheetHeight: CGFloat = 200
    static let contentSpacing: CGFloat = 16
    static let buttonContentSpacing: CGFloat = 8
    static let buttonVerticalPadding: CGFloat = 12
    static let buttonHorizontalPadding: CGFloat = 32
    static let borderWidth: CGFloat = 1
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
        .sheet(isPresented: $showAccountMenu) {
            accountMenuView
                .presentationDetents([.height(NavBarAuthButtonConstants.sheetHeight)])
                .presentationDragIndicator(.visible)
        }
    }

    private var accountMenuView: some View {
        VStack(spacing: NavBarAuthButtonConstants.contentSpacing) {
            if let user = authState.user {
                Text(user.name)
                    .adaptiveFont(.headline)
                    .foregroundStyle(VERACommonUIAsset.SemanticColors.textPrimary.swiftUIColor)

                if let email = user.email {
                    Text(email)
                        .adaptiveFont(.bodyBase)
                        .foregroundStyle(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
                }
            }

            Button(role: .destructive) {
                Task {
                    isLoggingOut = true
                    await onLogoutTapped()
                    isLoggingOut = false
                    showAccountMenu = false
                }
            } label: {
                HStack(spacing: NavBarAuthButtonConstants.buttonContentSpacing) {
                    if isLoggingOut {
                        ProgressView()
                            .tint(VERACommonUIAsset.SemanticColors.error.swiftUIColor)
                    }
                    Text("auth_sign_out", bundle: .module)
                        .adaptiveFont(.bodyBaseSemibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, NavBarAuthButtonConstants.buttonVerticalPadding)
            }
            .foregroundStyle(VERACommonUIAsset.SemanticColors.error.swiftUIColor)
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.medium.value)
                    .stroke(
                        VERACommonUIAsset.SemanticColors.border.swiftUIColor,
                        lineWidth: NavBarAuthButtonConstants.borderWidth
                    )
            )
            .cornerRadius(.medium)
            .disabled(isLoggingOut)
            .padding(.horizontal, NavBarAuthButtonConstants.buttonHorizontalPadding)
        }
        .padding()
    }
}
