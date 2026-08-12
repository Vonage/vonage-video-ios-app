//
//  Created by Vonage on 12/8/26.
//

import SwiftUI
import VERADomain

/// A compact sheet view that presents available identity providers for sign-in.
///
/// Designed to be presented with a small detent from the landing page nav bar.
/// Receives a list of `IDProvider`s and delegates the sign-in action for
/// the selected provider to the composition root.
public struct SignInView: View {
    private let providers: [IDProvider]
    private let onProviderSelected: (IDProvider) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?

    /// - Parameters:
    ///   - providers: The list of identity providers to display.
    ///   - onProviderSelected: Called when the user selects a provider to sign in with.
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

            // Title
            VStack(spacing: 8) {
                Text("sign_in_title", bundle: .veraOKTA)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("sign_in_subtitle", bundle: .veraOKTA)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Error message
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Provider buttons
            ForEach(providers) { provider in
                Button {
                    Task {
                        await performSignIn(with: provider)
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Sign in with \(provider.displayName)")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
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
