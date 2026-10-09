//
//  Created by Vonage on 12/8/26.
//

import Foundation

public struct AuthenticatedUser: Equatable, Sendable {
    public let name: String?

    public init(name: String? = nil) {
        self.name = name
    }
}

public enum AuthState: Equatable {
    case notAuthenticated
    case authenticated(AuthenticatedUser)

    public var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }

    public var user: AuthenticatedUser? {
        if case .authenticated(let user) = self { return user }
        return nil
    }
}
