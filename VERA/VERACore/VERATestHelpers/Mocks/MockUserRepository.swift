//
//  Created by Vonage on 17/7/25.
//

import Foundation
import VERACore

public final class MockUserRepository: UserRepository {

    public enum Action: Equatable {
        case save(User)
        case get
    }

    public var actions: [Action] = []

    public var user: VERACore.User?

    public func save(_ user: VERACore.User) async throws {
        actions.append(Action.save(user))
        self.user = user
    }

    public func get() async throws -> VERACore.User? {
        actions.append(Action.get)
        return user
    }
}

public func makeMockUserRepository() -> MockUserRepository {
    MockUserRepository()
}
