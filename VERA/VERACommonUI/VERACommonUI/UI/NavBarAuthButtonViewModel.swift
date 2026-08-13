//
//  Created by Vonage on 12/8/26.
//

import Combine
import Foundation
import VERADomain

@MainActor
public final class NavBarAuthButtonViewModel: ObservableObject {

    @Published public private(set) var authState: AuthState = .notAuthenticated

    public var onLoginTapped: () -> Void
    public var onLogoutTapped: () async -> Void

    private let authStateDataSource: AuthStateDataSource
    private var cancellables = Set<AnyCancellable>()

    public init(
        authStateDataSource: AuthStateDataSource,
        onLoginTapped: @escaping () -> Void,
        onLogoutTapped: @escaping () async -> Void
    ) {
        self.authStateDataSource = authStateDataSource
        self.onLoginTapped = onLoginTapped
        self.onLogoutTapped = onLogoutTapped
    }

    public func startObserving() {
        authStateDataSource.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.authState = state
            }
            .store(in: &cancellables)
    }
}
