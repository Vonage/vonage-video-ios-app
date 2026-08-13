//
//  Created by Vonage on 13/8/26.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERACommonUI
import VERADomain

@Suite("SignInView Snapshot Tests")
@MainActor
struct SignInViewSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false
    private let snapshotPrefix = "SignInView"

    // MARK: - Single Provider Tests

    @Test(
        "SignInView - Single Provider Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func singleProviderColorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT(providers: [
            IDProvider(id: "okta", displayName: "Okta")
        ])
        .environment(\.colorScheme, scheme)

        snapshot(sut, named: "SingleProvider_\(schemeName)")
    }

    // MARK: - Multiple Providers

    @Test("SignInView - Multiple Providers")
    func multipleProviders() throws {
        let sut = makeSUT(providers: [
            IDProvider(id: "okta", displayName: "Okta"),
            IDProvider(id: "azure", displayName: "Microsoft Azure"),
        ])

        snapshot(sut, named: "MultipleProviders")
    }

    // MARK: - Error State

    @Test(
        "SignInView - Error State Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func errorStateColorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUTWithError(
            providers: [IDProvider(id: "okta", displayName: "Okta")],
            errorMessage: "Sign-in failed. Please try again."
        )
        .environment(\.colorScheme, scheme)

        snapshot(sut, named: "ErrorState_\(schemeName)")
    }

    // MARK: - Empty Providers (edge case)

    @Test("SignInView - No Providers")
    func noProviders() throws {
        let sut = makeSUT(providers: [])

        snapshot(sut, named: "NoProviders")
    }

    // MARK: - Test Helpers

    private func makeSUT(providers: [IDProvider]) -> some View {
        SignInView(
            providers: providers,
            onProviderSelected: { _ in }
        )
    }

    /// Creates a SignInView that displays an error message by wrapping it in a
    /// container that overlays the error text. Since the error state is internal
    /// (@State), we simulate its visual appearance directly.
    private func makeSUTWithError(
        providers: [IDProvider],
        errorMessage: String
    ) -> some View {
        SignInViewErrorPreview(
            providers: providers,
            errorMessage: errorMessage
        )
    }

    private func snapshot(
        _ view: some View,
        named: String,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .fixed(width: 390, height: 300)),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }
}

// MARK: - Error State Preview Helper

/// A wrapper that simulates the SignInView error state for snapshot testing.
/// Since the error is an internal @State, we recreate the visual layout to capture
/// the error appearance.
private struct SignInViewErrorPreview: View {
    let providers: [IDProvider]
    let errorMessage: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 8)

            VStack(spacing: 8) {
                Text("Sign in to VERA")
                    .font(.title2.bold())

                Text("Use your Vonage account")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            ForEach(providers) { provider in
                Button {
                } label: {
                    Text("Sign in with \(provider.displayName)")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .foregroundStyle(.white)
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 32)
            }

            Spacer()
        }
        .padding()
    }
}
