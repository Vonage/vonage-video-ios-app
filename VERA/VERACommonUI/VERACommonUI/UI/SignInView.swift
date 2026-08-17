//
//  Created by Vonage on 12/8/26.
//

import SwiftUI
import VERADomain

private enum SignInViewConstants {
    static let sectionSpacing: CGFloat = 24
    static let titleSpacing: CGFloat = 8
    static let topInset: CGFloat = 8
    static let buttonContentSpacing: CGFloat = 8
    static let buttonVerticalPadding: CGFloat = 14
    static let buttonHorizontalPadding: CGFloat = 32
    static let sheetHeight: CGFloat = 200
}

public struct SignInView: View {
    private let providers: [IDProvider]
    private let onProviderSelected: (IDProvider) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?

    public init(
        providers: [IDProvider],
        onProviderSelected: @escaping (IDProvider) async throws -> Void,
        initialErrorMessage: String? = nil
    ) {
        self.providers = providers
        self.onProviderSelected = onProviderSelected
        self._errorMessage = State(initialValue: initialErrorMessage)
    }

    public var body: some View {
        ZStack {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityElement()
                .accessibilityIdentifier("auth-sign-in-screen")

            VStack(spacing: SignInViewConstants.sectionSpacing) {
                Spacer()
                    .frame(height: SignInViewConstants.topInset)

                VStack(spacing: SignInViewConstants.titleSpacing) {
                    Text("auth_sign_in_title", bundle: .module)
                        .adaptiveFont(.heading2)
                        .foregroundStyle(VERACommonUIAsset.SemanticColors.textPrimary.swiftUIColor)
                        .accessibilityIdentifier("auth-sign-in-title")

                    Text("auth_sign_in_subtitle", bundle: .module)
                        .adaptiveFont(.bodyBase)
                        .foregroundStyle(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
                        .accessibilityIdentifier("auth-sign-in-subtitle")
                }

                if let errorMessage {
                    Text(errorMessage)
                        .adaptiveFont(.caption)
                        .foregroundStyle(VERACommonUIAsset.SemanticColors.error.swiftUIColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .accessibilityIdentifier("auth-sign-in-error")
                }

                ForEach(providers) { provider in
                    Button {
                        Task {
                            await performSignIn(with: provider)
                        }
                    } label: {
                        HStack(spacing: SignInViewConstants.buttonContentSpacing) {
                            if isLoading {
                                ProgressView()
                                    .tint(VERACommonUIAsset.SemanticColors.onPrimary.swiftUIColor)
                            }
                            Text("auth_sign_in_with \(provider.displayName)", bundle: .module)
                                .adaptiveFont(.bodyBaseSemibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SignInViewConstants.buttonVerticalPadding)
                    }
                    .foregroundStyle(VERACommonUIAsset.SemanticColors.onPrimary.swiftUIColor)
                    .background(VERACommonUIAsset.SemanticColors.primary.swiftUIColor)
                    .cornerRadius(.medium)
                    .disabled(isLoading)
                    .padding(.horizontal, SignInViewConstants.buttonHorizontalPadding)
                    .accessibilityIdentifier("auth-sign-in-provider-\(provider.id)")
                }

                Spacer()
            }
            .padding()
        }
    }

    @MainActor
    private func performSignIn(with provider: IDProvider) async {
        isLoading = true
        errorMessage = nil

        do {
            try await onProviderSelected(provider)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
