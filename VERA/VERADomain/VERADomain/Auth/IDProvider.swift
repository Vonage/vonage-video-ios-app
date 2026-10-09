//
//  Created by Vonage on 12/8/26.
//

import Foundation

/// Represents an identity provider available for sign-in.
public struct IDProvider: Identifiable, Equatable {
    public let id: String
    public let displayName: String

    public init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}
