//
//  Created by Vonage on 12/8/26.
//

import SwiftUI
import VERADomain

private enum NavBarAuthButtonConstants {
    static let sheetHeight: CGFloat = 200
}

public struct NavBarAuthButton: View {
    @ObservedObject private var viewModel: NavBarAuthButtonViewModel

    public init(viewModel: NavBarAuthButtonViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Button {
            viewModel.authButtonTapped()
        } label: {
            switch viewModel.authState {
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
        .sheet(isPresented: $viewModel.showAccountMenu) {
            accountMenuView
                .presentationDetents([.height(NavBarAuthButtonConstants.sheetHeight)])
                .presentationDragIndicator(.visible)
        }
    }

    private var accountMenuView: some View {
        AuthAccountMenuView(
            userName: viewModel.authState.user?.name,
            isLoggingOut: viewModel.isLoggingOut
        ) {
            Task { await viewModel.signOut() }
        }
    }
}
