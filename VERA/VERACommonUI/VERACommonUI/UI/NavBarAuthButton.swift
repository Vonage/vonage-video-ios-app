//
//  Created by Vonage on 12/8/26.
//

import SwiftUI
import VERADomain

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
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
        }
    }

    private var accountMenuView: some View {
        VStack(spacing: 16) {
            if let user = authState.user, let name = user.name {
                Text(name)
                    .adaptiveFont(.headline)
                    .foregroundStyle(VERACommonUIAsset.SemanticColors.textPrimary.swiftUIColor)
            }

            Button(role: .destructive) {
                Task {
                    isLoggingOut = true
                    await onLogoutTapped()
                    isLoggingOut = false
                    showAccountMenu = false
                }
            } label: {
                HStack(spacing: 8) {
                    if isLoggingOut {
                        ProgressView()
                            .tint(VERACommonUIAsset.SemanticColors.error.swiftUIColor)
                    }
                    Text("auth_sign_out", bundle: .module)
                        .adaptiveFont(.bodyBaseSemibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .foregroundStyle(VERACommonUIAsset.SemanticColors.error.swiftUIColor)
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.medium.value)
                    .stroke(VERACommonUIAsset.SemanticColors.border.swiftUIColor, lineWidth: 1)
            )
            .cornerRadius(.medium)
            .disabled(isLoggingOut)
            .padding(.horizontal, 32)
        }
        .padding()
    }
}
