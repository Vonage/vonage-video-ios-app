//
//  Created by Vonage on 17/12/25.
//

import Foundation

public typealias Username = String

extension Username {
    public static var maxUsernameLength: Int { 60 }

    public var isValidUsername: Bool {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return (1...Username.maxUsernameLength).contains(trimmed.count)
    }
}
