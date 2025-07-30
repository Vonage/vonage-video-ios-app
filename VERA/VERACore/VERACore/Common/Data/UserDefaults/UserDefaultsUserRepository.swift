//
//  Created by Vonage on 16/7/25.
//

import Foundation

public final class UserDefaultsUserRepository: UserRepository {

    private let userDefaults: UserDefaults

    enum CodingKeys: String {
        case name
    }

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func save(_ user: User) async throws {
        userDefaults.setValue(user.name, forKey: CodingKeys.name.rawValue)
    }

    public func get() async throws -> User? {
        guard let name = userDefaults.string(forKey: CodingKeys.name.rawValue) else {
            return nil
        }
        return User(name: name)
    }
}
