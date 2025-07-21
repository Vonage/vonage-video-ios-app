//
//  Created by Vonage on 16/7/25.
//

import Foundation
import VERACore

final class UserDefaultsUserRepository: UserRepository {

    private let userDefaults: UserDefaults

    enum CodingKeys: String {
        case name
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func save(_ user: VERACore.User) async throws {
        userDefaults.setValue(user.name, forKey: CodingKeys.name.rawValue)
    }

    func get() async throws -> VERACore.User? {
        guard let name = userDefaults.string(forKey: CodingKeys.name.rawValue) else {
            return nil
        }
        return User(name: name)
    }
}
