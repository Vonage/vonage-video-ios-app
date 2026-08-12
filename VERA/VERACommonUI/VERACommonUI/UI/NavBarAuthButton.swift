//
//  Created by Vonage on 12/8/26.
//

import SwiftUI
import VERADomain

/// A toolbar button that shows the user's authentication state.
///
/// - Not authenticated: Shows a `person.circle` icon. Tapping delegates login to the composition root.
/// - Authenticated: Shows the user's initials in a circular badge.
///   Tapping shows a sign-out confirmation sheet.
///
/// This view is completely decoupled from any specific identity provider.
public struct NavBarAuthButton: View {
    @ObservedObject private var viewModel: NavBarAuthButtonViewModel
    @State private var showAccountMenu = false
    @State private var isLoggingOut = false

    public init(viewModel: NavBarAuthButtonViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Button {
            switch viewModel.authState {
            case .notAuthenticated:
                viewModel.onLoginTapped()
            case .authenticated:
                showAccountMenu = true
            }
        } label: {
            switch viewModel.authState {
            case .notAuthenticated:
                Image(systemName: "person.circle")
                    .font(.title3)
                    .accessibilityLabel("Sign in")
            case .authenticated(let user):
                initialsView(for: user)
            }
        }
        .sheet(isPresented: $showAccountMenu) {
            accountMenuView
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            viewModel.startObserving()
        }
    }

    // MARK: - Private Views

    private func initialsView(for user: AuthenticatedUser) -> some View {
        Text(user.initials)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(
                Circle()
                    .fill(VERACommonUIAsset.SemanticColors.primary.swiftUIColor)
            )
            .accessibilityLabel(Text(user.name))
    }

    private var accountMenuView: some View {
        VStack(spacing: 16) {
            if let user = viewModel.authState.user {
                Text(user.name)
                    .font(.headline)

                Text(user.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                Task {
                    isLoggingOut = true
                    await viewModel.onLogoutTapped()
                    isLoggingOut = false
                    showAccountMenu = false
                }
            } label: {
                HStack(spacing: 8) {
                    if isLoggingOut {
                        ProgressView()
                            .tint(.red)
                    }
                    Text("Sign out")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .disabled(isLoggingOut)
            .padding(.horizontal, 32)
        }
        .padding()
    }
}
