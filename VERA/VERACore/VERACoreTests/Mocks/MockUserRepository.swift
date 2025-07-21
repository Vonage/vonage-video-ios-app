//
//  Created by Vonage on 17/7/25.
//

import Foundation
import VERACore

final class MockUserRepository: UserRepository {

    enum Action {
        case save(User)
        case get
    }

    var actions: [Action] = []

    var user: VERACore.User?

    func save(_ user: VERACore.User) async throws {
        actions.append(Action.save(user))
        self.user = user
    }

    func get() async throws -> VERACore.User? {
        actions.append(Action.get)
        return user
    }
}

func makeMockUserRepository() -> MockUserRepository {
    MockUserRepository()
}
