//
//  Created by Vonage on 16/7/25.
//

import Foundation

public protocol UserRepository: Sendable {
    func save(_ user: User) async throws
    func get() async throws -> User?
}
