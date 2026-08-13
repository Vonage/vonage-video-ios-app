//
//  Created by Vonage on 12/8/26.
//

import SwiftUI
import VERACommonUI
import VERADomain

public struct SignInView: View {
    private let providers: [IDProvider]
    private let onProviderSelected: (IDProvider) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?

    public init(
        providers: [IDProvider],
        onProviderSelected: @escaping (IDProvider) async throws -> Void
    ) {
        self.providers = providers
        self.onProviderSelected = onProviderSelected
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 8)

            VStack(spacing: 8) {
                Text("sign_in_title", bundle: .veraOKTA)
                    .adaptiveFont(.heading2)
                    .foregroundStyle(VERACommonUIAsset.SemanticColors.textPrimary.swiftUIColor)

                Text("sign_in_subtitle", bundle: .veraOKTA)
                    .adaptiveFont(.bodyBase)
                    .foregroundStyle(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
            }

            if let errorMessage {
                Text(errorMessage)
                    .adaptiveFont(.caption)
                    .foregroundStyle(VERACommonUIAsset.SemanticColors.error.swiftUIColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            ForEach(providers) { provider in
                Button {
                    Task {
                        await performSignIn(with: provider)
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .tint(VERACommonUIAsset.SemanticColors.onPrimary.swiftUIColor)
                        }
                        Text("Sign in with \(provider.displayName)")
                            .adaptiveFont(.bodyBaseSemibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .foregroundStyle(VERACommonUIAsset.SemanticColors.onPrimary.swiftUIColor)
                .background(VERACommonUIAsset.SemanticColors.primary.swiftUIColor)
                .cornerRadius(.medium)
                .disabled(isLoading)
                .padding(.horizontal, 32)
            }

            Spacer()
        }
        .padding()
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
