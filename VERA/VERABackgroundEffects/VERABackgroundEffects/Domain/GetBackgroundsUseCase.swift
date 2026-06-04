//
//  Created by Vonage on 31/05/2026.
//

import Foundation
import VERADomain

/// Merges stock and user-uploaded backgrounds into a single list.
public protocol GetBackgroundsUseCase {
    func callAsFunction() throws -> GetBackgroundsUseCaseResult
}

public struct GetBackgroundsUseCaseResult {
    public let backgrounds: [VideoBackgroundItem]

    public init(backgrounds: [VideoBackgroundItem]) {
        self.backgrounds = backgrounds
    }
}

public final class DefaultGetBackgroundsUseCase: GetBackgroundsUseCase {

    private let backgroundEffectsRepository: BackgroundEffectsRepository
    private let userBackgroundRepository: UserBackgroundRepository

    public init(
        backgroundEffectsRepository: BackgroundEffectsRepository,
        userBackgroundRepository: UserBackgroundRepository
    ) {
        self.backgroundEffectsRepository = backgroundEffectsRepository
        self.userBackgroundRepository = userBackgroundRepository
    }

    public func callAsFunction() throws -> GetBackgroundsUseCaseResult {
        let stock = try backgroundEffectsRepository.availableBackgrounds()
        let user = try userBackgroundRepository.savedBackgrounds()
        return GetBackgroundsUseCaseResult(backgrounds: stock + user)
    }
}
