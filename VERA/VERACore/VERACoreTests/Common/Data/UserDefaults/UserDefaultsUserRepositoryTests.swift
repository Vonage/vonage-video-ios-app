//
//  Created by Vonage on 2/4/26.
//

import Foundation
import Testing
import VERACore

@Suite("UserDefaultsUserRepository tests")
struct UserDefaultsUserRepositoryTests {

    private func makeSUT() -> (UserDefaultsUserRepository, String) {
        let suiteName = "test-user-repo-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        let sut = UserDefaultsUserRepository(userDefaults: userDefaults)
        return (sut, suiteName)
    }

    @Test("Save and retrieve user")
    func saveAndRetrieveUser() async throws {
        let (sut, suiteName) = makeSUT()

        let user = User(name: "Alice")
        try await sut.save(user)

        let retrieved = try await sut.get()
        #expect(retrieved?.name == "Alice")

        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    @Test("Get returns nil when no user saved")
    func getReturnsNilWhenEmpty() async throws {
        let (sut, suiteName) = makeSUT()

        let retrieved = try await sut.get()
        #expect(retrieved == nil)

        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    @Test("Save overwrites previous user")
    func saveOverwritesPreviousUser() async throws {
        let (sut, suiteName) = makeSUT()

        try await sut.save(User(name: "Alice"))
        try await sut.save(User(name: "Bob"))

        let retrieved = try await sut.get()
        #expect(retrieved?.name == "Bob")

        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    @Test("Save user with empty name")
    func saveUserWithEmptyName() async throws {
        let (sut, suiteName) = makeSUT()

        try await sut.save(User(name: ""))

        let retrieved = try await sut.get()
        #expect(retrieved?.name == "")

        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }
}
