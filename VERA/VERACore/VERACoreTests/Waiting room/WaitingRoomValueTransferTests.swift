//
//  Created by Vonage on 14/10/2026.
//

import Testing

@testable import VERACore

@Suite("Waiting-room value transfer")
struct WaitingRoomValueTransferTests {
    @Test("Customer actors can implement the existing user repository protocol")
    func usersAcrossTasksAndRepositoryActor() async throws {
        let storage = UserStorage()
        let repository: any UserRepository = storage
        #expect(try await repository.get() == nil)

        for name in ["", "Zoë 東京"] {
            let user = await transfer(User(name: name))
            try await repository.save(user)
            #expect(try await repository.get() == user)
        }
    }

    @Test("Renaming a transferred user leaves the original and actor snapshot unchanged")
    func renamedUsersRemainIndependent() async throws {
        let original = User(name: "Original")
        let storage = UserStorage()
        try await storage.save(original)
        let renamed = await Task.detached { original.updateName("Replacement") }.value
        #expect(renamed == User(name: "Replacement"))
        #expect(original == User(name: "Original"))
        #expect(try await storage.get() == original)
    }

    @Test("Join requests retain room and user names across task and actor boundaries")
    func joinRequestsAcrossTasksAndActor() async {
        let requests = [
            JoinRoomRequest(roomName: "", userName: ""),
            JoinRoomRequest(roomName: "room/東京?version=2", userName: "Zoë Smith"),
        ]
        let storage = JoinRequestStorage()
        for request in requests {
            await storage.append(await transfer(request))
        }
        let received = await storage.requests
        #expect(received.map(\.roomName) == requests.map(\.roomName))
        #expect(received.map(\.userName) == requests.map(\.userName))
    }

    private func transfer<Value: Sendable>(_ value: Value) async -> Value {
        await Task.detached { value }.value
    }
}

private actor UserStorage: UserRepository {
    private var user: User?

    func save(_ user: User) async throws {
        self.user = user
    }

    func get() async throws -> User? {
        user
    }
}

private actor JoinRequestStorage {
    private(set) var requests: [JoinRoomRequest] = []

    func append(_ request: JoinRoomRequest) {
        requests.append(request)
    }
}
