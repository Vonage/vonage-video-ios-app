//
//  Created by Vonage on 31/05/2026.
//

import Foundation
import VERADomain

/// Deletes a user-uploaded background and resets the active effect if it was the deleted one.
public struct DeleteBackgroundUseCase {

    private let userBackgroundRepository: UserBackgroundRepository
    private let videoEffectRepository: VideoEffectRepository

    public init(
        userBackgroundRepository: UserBackgroundRepository,
        videoEffectRepository: VideoEffectRepository
    ) {
        self.userBackgroundRepository = userBackgroundRepository
        self.videoEffectRepository = videoEffectRepository
    }

    /// Deletes the background and returns `true` if the active effect was reset to `.none`.
    @discardableResult
    public func execute(_ id: String) throws -> Bool {
        try userBackgroundRepository.delete(id)

        let currentEffect = videoEffectRepository.load()
        if case .backgroundImage(let activeId, _) = currentEffect, activeId == id {
            try videoEffectRepository.save(.none)
            return true
        }
        return false
    }
}
