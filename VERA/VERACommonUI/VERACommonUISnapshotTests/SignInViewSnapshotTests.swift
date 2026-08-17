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
        let sut = makeSUT(
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

    private func makeSUT(
        providers: [IDProvider],
        errorMessage: String? = nil
    ) -> some View {
        SignInView(
            providers: providers,
            onProviderSelected: { _ in },
            initialErrorMessage: errorMessage
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
