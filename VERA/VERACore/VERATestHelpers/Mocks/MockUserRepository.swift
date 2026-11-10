//
//  Created by Vonage on 17/7/25.
//

import Foundation
import VERACore

public final class MockUserRepository: UserRepository {

    public enum Action: Equatable, Sendable {
        case save(User)
        case get
    }

    private struct State: Sendable {
        var actions: [Action] = []
        var user: User?
    }

    private let state = TestLockedValue(State())

    public var actions: [Action] {
        get { state.withValue { $0.actions } }
        set { state.withValue { $0.actions = newValue } }
    }

    public var user: User? {
        get { state.withValue { $0.user } }
        set { state.withValue { $0.user = newValue } }
    }

    public func save(_ user: User) async throws {
        state.withValue {
            $0.actions.append(.save(user))
            $0.user = user
        }
    }

    public func get() async throws -> User? {
        state.withValue {
            $0.actions.append(.get)
            return $0.user
        }
    }
}

public func makeMockUserRepository() -> MockUserRepository {
    MockUserRepository()
}
