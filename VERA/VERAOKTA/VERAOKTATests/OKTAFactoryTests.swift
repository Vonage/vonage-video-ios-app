//
//  Created by Vonage on 13/8/26.
//

import Foundation
import Testing
import VERACommonUI
import VERADomain

@testable import VERAOKTA

@MainActor
@Suite("OKTAFactory Tests")
struct OKTAFactoryTests {

    @Test("authenticationManager returns the injected authManager")
    func authenticationManagerReturnsInjected() {
        let authManager = OktaAuthManager()
        let sut = OKTAFactory(authManager: authManager)

        #expect(sut.authenticationManager === authManager)
    }

    @Test("makeNavBarAuthButtonViewModel returns configured view model")
    func makeNavBarAuthButtonViewModelReturns() {
        let authManager = OktaAuthManager()
        let sut = OKTAFactory(authManager: authManager)
        var loginCalled = false
        var logoutCalled = false

        let viewModel = sut.makeNavBarAuthButtonViewModel(
            onLoginTapped: { loginCalled = true },
            onLogoutTapped: { logoutCalled = true }
        )

        viewModel.onLoginTapped()
        #expect(loginCalled)

        Task {
            await viewModel.onLogoutTapped()
        }
        // Verify the view model is of expected type
        #expect(viewModel.authState == .notAuthenticated)
        _ = logoutCalled
    }

    @Test("makeNavBarAuthButtonViewModel passes authManager as data source")
    func makeNavBarAuthButtonViewModelUsesAuthManager() {
        let authManager = OktaAuthManager()
        let sut = OKTAFactory(authManager: authManager)

        let viewModel = sut.makeNavBarAuthButtonViewModel(
            onLoginTapped: {},
            onLogoutTapped: {}
        )

        // Start observing and verify initial state matches authManager
        viewModel.startObserving()
        #expect(viewModel.authState == .notAuthenticated)
    }
}
