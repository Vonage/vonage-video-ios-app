//
//  Created by Vonage on 12/8/26.
//

import Foundation

/// Represents an authenticated user with their profile information.
public struct AuthenticatedUser: Equatable, Sendable {
    public let email: String
    public let name: String

    public init(email: String, name: String) {
        self.email = email
        self.name = name
    }

    /// Returns the user's initials (up to 2 characters) derived from their name.
    public var initials: String {
        let parts =
            name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)

        if parts.isEmpty {
            return String(name.prefix(2)).uppercased()
        }

        return parts.joined().uppercased()
    }
}

/// Represents the authentication state of the user.
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
