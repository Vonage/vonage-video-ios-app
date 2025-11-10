//
//  Created by Vonage on 16/7/25.
//

import Foundation

public struct User: Equatable {
    public let name: String

    public init(name: String) {
        self.name = name
    }

    func updateName(_ newName: String) -> User {
        return User(name: newName)
    }
}
