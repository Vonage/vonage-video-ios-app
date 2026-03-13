//
//  Created by Vonage on 6/2/26.
//

import Foundation
import OSLog
import VERADomain

public protocol EnableNoiseSuppressionUseCase {
    func callAsFunction(publisher: VERAPublisher)
}

public final class DefaultEnableNoiseSuppressionUseCase: EnableNoiseSuppressionUseCase {

    private let logger = Logger(
        subsystem: "com.vonage.VERAAudioEffects",
        category: "DefaultEnableNoiseSuppressionUseCase")

    private final let noiseSuppressionStatusDataSource: NoiseSuppressionStatusDataSource

    public init(noiseSuppressionStatusDataSource: NoiseSuppressionStatusDataSource) {
        self.noiseSuppressionStatusDataSource = noiseSuppressionStatusDataSource
    }

    public func callAsFunction(publisher: VERAPublisher) {
        do {
            try publisher.setNoiseSuppression(enabled: true)

            noiseSuppressionStatusDataSource.set(state: .enabled)
        } catch {
            logger.error("\(error.localizedDescription)")
        }
    }
}
