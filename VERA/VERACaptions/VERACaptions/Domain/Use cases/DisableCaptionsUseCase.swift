//
//  Created by Vonage on 6/2/26.
//

import Foundation
import VERADomain

public protocol DisableCaptionsUseCase {
    func callAsFunction()
}

public final class DefaultDisableCaptionsUseCase: DisableCaptionsUseCase {

    private let captionsStatusDataSource: CaptionsStatusDataSource

    public init(captionsStatusDataSource: CaptionsStatusDataSource) {
        self.captionsStatusDataSource = captionsStatusDataSource
    }

    public func callAsFunction() {
        captionsStatusDataSource.set(captionsState: .disabled)
    }
}
