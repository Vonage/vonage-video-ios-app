//
//  Created by Vonage on 31/05/2026.
//

import Foundation
import VERADomain

/// Merges stock and user-uploaded backgrounds into a single list and computes remaining upload slots.
public struct GetBackgroundsUseCase {

    private let backgroundEffectsRepository: BackgroundEffectsRepository
    private let userBackgroundRepository: UserBackgroundRepository

    public init(
        backgroundEffectsRepository: BackgroundEffectsRepository,
        userBackgroundRepository: UserBackgroundRepository
    ) {
        self.backgroundEffectsRepository = backgroundEffectsRepository
        self.userBackgroundRepository = userBackgroundRepository
    }

    public struct Result {
        public let backgrounds: [VideoBackgroundItem]
        public let remainingSlots: Int
    }

    public func execute() throws -> Result {
        let stock = try backgroundEffectsRepository.availableBackgrounds()
        let user = try userBackgroundRepository.savedBackgrounds()
        return Result(
            backgrounds: stock + user,
            remainingSlots: userBackgroundRepository.remainingSlots
        )
    }
}
