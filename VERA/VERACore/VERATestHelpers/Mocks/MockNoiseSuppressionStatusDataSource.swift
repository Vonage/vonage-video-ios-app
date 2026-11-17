//
//  Created by Vonage on 13/03/2026.
//

import Combine
import VERADomain

public func makeMockNoiseSuppressionStatusDataSource() -> NoiseSuppressionStatusDataSource {
    MockNoiseSuppressionStatusDataSource()
}

public final class MockNoiseSuppressionStatusDataSource: NoiseSuppressionStatusDataSource {

    public let _noiseSuppressionState = CurrentValueRelay<NoiseSuppressionState, Never>(.idle)

    public var noiseSuppressionState: AnyPublisher<NoiseSuppressionState, Never> {
        _noiseSuppressionState.publisher
    }

    public func set(state: VERADomain.NoiseSuppressionState) {
        _noiseSuppressionState.send(state)
    }
}
