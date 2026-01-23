//
//  Created by Vonage on 22/1/26.
//

import Foundation

extension ArchivingState {
    public var isArchiving: Bool {
        if case .archiving = self {
            return true
        }
        return false
    }
}
