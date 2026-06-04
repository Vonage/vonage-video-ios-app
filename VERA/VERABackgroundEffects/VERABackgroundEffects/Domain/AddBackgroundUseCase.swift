//
//  Created by Vonage on 31/05/2026.
//

import Foundation
import VERADomain

/// Saves a user-selected photo as a new background image after cropping.
public protocol AddBackgroundUseCase {
    func callAsFunction(_ imageData: Data) throws -> VideoBackgroundItem
}

public final class DefaultAddBackgroundUseCase: AddBackgroundUseCase {

    private let userBackgroundRepository: UserBackgroundRepository

    public init(userBackgroundRepository: UserBackgroundRepository) {
        self.userBackgroundRepository = userBackgroundRepository
    }

    public func callAsFunction(_ imageData: Data) throws -> VideoBackgroundItem {
        try userBackgroundRepository.save(imageData)
    }
}
