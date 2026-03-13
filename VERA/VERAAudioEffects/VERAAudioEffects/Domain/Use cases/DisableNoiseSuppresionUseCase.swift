//
//  Created by Vonage on 6/2/26.
//

import Foundation
import VERADomain

public protocol DisableNoiseSuppresionUseCase {
    func callAsFunction()
}

public final class DefaultDisableNoiseSuppressionUseCase: DisableNoiseSuppresionUseCase {

    private let noiseSuppressionStatusDataSource: NoiseSuppressionStatusDataSource

    public init(noiseSuppressionStatusDataSource: NoiseSuppressionStatusDataSource) {
        self.noiseSuppressionStatusDataSource = noiseSuppressionStatusDataSource
    }

    public func callAsFunction() {
        noiseSuppressionStatusDataSource.set(state: .disabled)
    }
}
