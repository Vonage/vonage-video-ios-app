//
//  Created by Vonage on 31/05/2026.
//

import Foundation
import VERADomain

/// Saves a user-selected photo as a new background image after cropping.
public struct AddBackgroundUseCase {

    private let userBackgroundRepository: UserBackgroundRepository

    public init(userBackgroundRepository: UserBackgroundRepository) {
        self.userBackgroundRepository = userBackgroundRepository
    }

    public func execute(_ imageData: Data) throws -> VideoBackgroundItem {
        guard userBackgroundRepository.remainingSlots > 0 else {
            throw UserBackgroundError.maxSlotsReached
        }
        return try userBackgroundRepository.save(imageData)
    }
}
