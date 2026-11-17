import Foundation
import Testing

@testable import VERACore

@MainActor
@Suite("User preferences ownership")
struct UserDefaultsUserRepositoryOwnershipTests {
    @Test("UI-owned preferences can be read through the asynchronous repository from another task")
    func readsSavedUserAcrossActorBoundary() async throws {
        let suiteName = "VERA.UserDefaultsUserRepositoryTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let repository = UserDefaultsUserRepository(userDefaults: defaults)
        let user = User(name: "Ada")

        try await repository.save(user)
        let result = try await Task.detached { try await repository.get() }.value

        #expect(result == user)
        #expect(defaults.string(forKey: "name") == user.name)
    }
}
