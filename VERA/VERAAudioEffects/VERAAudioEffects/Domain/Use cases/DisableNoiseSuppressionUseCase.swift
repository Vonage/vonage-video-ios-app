//
//  Created by Vonage on 6/2/26.
//

import Foundation
import OSLog
import VERADomain

public protocol DisableNoiseSuppressionUseCase {
    func callAsFunction(publisher: VERAPublisher)
}

public final class DefaultDisableNoiseSuppressionUseCase: DisableNoiseSuppressionUseCase {

    private let logger = Logger(
        subsystem: "com.vonage.VERAAudioEffects",
        category: "DefaultEnableNoiseSuppressionUseCase")

    private let noiseSuppressionStatusDataSource: NoiseSuppressionStatusDataSource

    public init(noiseSuppressionStatusDataSource: NoiseSuppressionStatusDataSource) {
        self.noiseSuppressionStatusDataSource = noiseSuppressionStatusDataSource
    }

    public func callAsFunction(publisher: VERAPublisher) {
        do {
            try publisher.setNoiseSuppression(enabled: false)

            noiseSuppressionStatusDataSource.set(state: .disabled)
        } catch {
            logger.error("\(error.localizedDescription)")
        }
    }
}
