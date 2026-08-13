//
//  Created by Vonage on 13/8/26.
//

import Combine
import Foundation
import Testing
import VERADomain

@testable import VERACommonUI

@MainActor
@Suite("NavBarAuthButtonViewModel Tests")
struct NavBarAuthButtonViewModelTests {

    // MARK: - Initial State

    @Test("initial authState is notAuthenticated")
    func initialState() {
        let sut = makeSUT()

        #expect(sut.authState == .notAuthenticated)
    }

    // MARK: - startObserving

    @Test("startObserving updates authState when data source publishes authenticated")
    func startObservingUpdatesState() async {
        let dataSource = MockAuthStateDataSource()
        let sut = makeSUT(dataSource: dataSource)

        sut.startObserving()
        dataSource.subject.send(.authenticated(AuthenticatedUser(name: "Alice")))
        await Task.yield()

        #expect(sut.authState == .authenticated(AuthenticatedUser(name: "Alice")))
    }

    @Test("startObserving reflects notAuthenticated after sign out")
    func startObservingReflectsSignOut() async {
        let dataSource = MockAuthStateDataSource()
        let sut = makeSUT(dataSource: dataSource)

        sut.startObserving()
        dataSource.subject.send(.authenticated(AuthenticatedUser(name: "Bob")))
        dataSource.subject.send(.notAuthenticated)
        await Task.yield()

        #expect(sut.authState == .notAuthenticated)
    }

    @Test("startObserving sets initial value from data source")
    func startObservingInitialValue() async {
        let dataSource = MockAuthStateDataSource(
            initialState: .authenticated(AuthenticatedUser(name: "Pre-auth"))
        )
        let sut = makeSUT(dataSource: dataSource)

        sut.startObserving()
        await Task.yield()

        #expect(sut.authState == .authenticated(AuthenticatedUser(name: "Pre-auth")))
    }

    // MARK: - Callbacks

    @Test("onLoginTapped invokes provided closure")
    func onLoginTappedInvokes() {
        var called = false
        let sut = makeSUT(onLoginTapped: { called = true })

        sut.onLoginTapped()

        #expect(called)
    }

    @Test("onLogoutTapped invokes provided closure")
    func onLogoutTappedInvokes() async {
        var called = false
        let sut = makeSUT(onLogoutTapped: { called = true })

        await sut.onLogoutTapped()

        #expect(called)
    }

    // MARK: - Multiple State Changes

    @Test("authState tracks multiple sequential changes")
    func multipleStateChanges() async {
        let dataSource = MockAuthStateDataSource()
        let sut = makeSUT(dataSource: dataSource)

        sut.startObserving()
        dataSource.subject.send(.authenticated(AuthenticatedUser(name: "User1")))
        dataSource.subject.send(.notAuthenticated)
        dataSource.subject.send(.authenticated(AuthenticatedUser(name: "User2")))
        await Task.yield()

        #expect(sut.authState == .authenticated(AuthenticatedUser(name: "User2")))
    }

    // MARK: - Helpers

    private func makeSUT(
        dataSource: MockAuthStateDataSource = MockAuthStateDataSource(),
        onLoginTapped: @escaping () -> Void = {},
        onLogoutTapped: @escaping () async -> Void = {}
    ) -> NavBarAuthButtonViewModel {
        NavBarAuthButtonViewModel(
            authStateDataSource: dataSource,
            onLoginTapped: onLoginTapped,
            onLogoutTapped: onLogoutTapped
        )
    }
}

// MARK: - Test Doubles

private final class MockAuthStateDataSource: AuthStateDataSource {
    let subject: CurrentValueSubject<AuthState, Never>

    var authStatePublisher: AnyPublisher<AuthState, Never> {
        subject.eraseToAnyPublisher()
    }

    init(initialState: AuthState = .notAuthenticated) {
        self.subject = CurrentValueSubject(initialState)
    }
}
