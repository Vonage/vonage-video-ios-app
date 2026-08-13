//
//  Created by Vonage on 13/8/26.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERACommonUI
import VERADomain

@Suite("NavBarAuthButton Snapshot Tests")
@MainActor
struct NavBarAuthButtonSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false
    private let snapshotPrefix = "NavBarAuthButton"

    // MARK: - Auth State Tests

    @Test(
        "NavBarAuthButton - Auth States",
        arguments: [
            ("NotAuthenticated", AuthState.notAuthenticated),
            ("Authenticated", AuthState.authenticated(AuthenticatedUser(name: "John Doe"))),
        ])
    func authStates(stateName: String, state: AuthState) throws {
        let sut = makeSUT(authState: state)

        snapshot(sut, named: "State_\(stateName)")
    }

    // MARK: - Color Scheme Tests

    @Test(
        "NavBarAuthButton - Not Authenticated Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func notAuthenticatedColorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT(authState: .notAuthenticated)
            .environment(\.colorScheme, scheme)

        snapshot(sut, named: "NotAuthenticated_\(schemeName)")
    }

    @Test(
        "NavBarAuthButton - Authenticated Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func authenticatedColorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT(authState: .authenticated(AuthenticatedUser(name: "Jane Smith")))
            .environment(\.colorScheme, scheme)

        snapshot(sut, named: "Authenticated_\(schemeName)")
    }

    // MARK: - All States Comparison

    @Test("NavBarAuthButton - All States Side by Side")
    func allStatesSideBySide() throws {
        let sut = HStack(spacing: 20) {
            NavBarAuthButton(
                authState: .notAuthenticated,
                onLoginTapped: {},
                onLogoutTapped: {}
            )
            NavBarAuthButton(
                authState: .authenticated(AuthenticatedUser(name: "User")),
                onLoginTapped: {},
                onLogoutTapped: {}
            )
        }
        .padding()
        .background(Color.gray.opacity(0.2))

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .sizeThatFits),
            named: "AllStates",
            record: isRecording,
            testName: "\(snapshotPrefix)_AllStates"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT(authState: AuthState) -> some View {
        ZStack {
            Color.gray.opacity(0.1)
                .ignoresSafeArea()

            NavBarAuthButton(
                authState: authState,
                onLoginTapped: {},
                onLogoutTapped: {}
            )
        }
    }

    private func snapshot(
        _ view: some View,
        named: String,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .fixed(width: 60, height: 60)),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }
}
