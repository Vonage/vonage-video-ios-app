//
//  Created by Vonage on 31/05/2026.
//

import Foundation
import VERADomain

/// Deletes a user-uploaded background.
public protocol DeleteBackgroundUseCase {
    func callAsFunction(_ id: String) throws
}

public final class DefaultDeleteBackgroundUseCase: DeleteBackgroundUseCase {

    private let userBackgroundRepository: UserBackgroundRepository

    public init(userBackgroundRepository: UserBackgroundRepository) {
        self.userBackgroundRepository = userBackgroundRepository
    }

    public func callAsFunction(_ id: String) throws {
        try userBackgroundRepository.delete(id)
    }
}
