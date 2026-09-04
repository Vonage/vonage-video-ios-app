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

    // MARK: - Account Menu (sheet content)

    @Test(
        "NavBarAuthButton - Account Menu shown when authenticated",
        arguments: [
            ("WithName", "John Doe"),
            ("WithoutName", nil as String?),
        ])
    func accountMenuPresented(caseName: String, userName: String?) throws {
        let sut = makeSUTWithAccountMenu(userName: userName)

        snapshot(sut, named: "AccountMenu_\(caseName)", size: CGSize(width: 320, height: 200))
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

    private func makeSUTWithAccountMenu(userName: String?) -> some View {
        AuthAccountMenuView(
            userName: userName,
            isLoggingOut: false,
            onSignOut: {}
        )
    }

    private func snapshot(
        _ view: some View,
        named: String,
        size: CGSize = CGSize(width: 60, height: 60),
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .fixed(width: size.width, height: size.height)),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }
}
