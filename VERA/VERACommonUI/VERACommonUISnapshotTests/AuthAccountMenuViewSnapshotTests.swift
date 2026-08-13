//
//  Created by Vonage on 13/8/26.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERACommonUI

@Suite("AuthAccountMenuView Snapshot Tests")
@MainActor
struct AuthAccountMenuViewSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false
    private let snapshotPrefix = "AuthAccountMenuView"

    // MARK: - Color Scheme Tests

    @Test(
        "AuthAccountMenuView - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT(userName: "John Doe")
            .environment(\.colorScheme, scheme)

        snapshot(sut, named: schemeName)
    }

    // MARK: - User Name Variants

    @Test(
        "AuthAccountMenuView - Name Variants",
        arguments: [
            ("ShortName", "Jo"),
            ("LongName", "Alexander Christopher Wellington III"),
            ("SingleWord", "Admin"),
        ])
    func nameVariants(variantName: String, userName: String) throws {
        let sut = makeSUT(userName: userName)

        snapshot(sut, named: "Name_\(variantName)")
    }

    // MARK: - No Name (nil user name)

    @Test("AuthAccountMenuView - No User Name")
    func noUserName() throws {
        let sut = makeSUT(userName: nil)

        snapshot(sut, named: "NoName")
    }

    // MARK: - Logging Out State

    @Test(
        "AuthAccountMenuView - Logging Out State",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func loggingOutState(schemeName: String, scheme: ColorScheme) throws {
        let sut = AuthAccountMenuView(
            userName: "John Doe",
            isLoggingOut: true,
            onSignOut: {}
        )
        .environment(\.colorScheme, scheme)

        snapshot(sut, named: "LoggingOut_\(schemeName)")
    }

    // MARK: - Test Helpers

    private func makeSUT(userName: String?) -> AuthAccountMenuView {
        AuthAccountMenuView(
            userName: userName,
            onSignOut: {}
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
            as: .image(precision: 0.99, layout: .fixed(width: 390, height: 200)),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }
}
