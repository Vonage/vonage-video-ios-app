//
//  Created by Vonage on 13/03/2026.
//

import Combine
import VERADomain

public func makeMockNoiseSuppressionStatusDataSource() -> NoiseSuppressionStatusDataSource {
    MockNoiseSuppressionStatusDataSource()
}

public final class MockNoiseSuppressionStatusDataSource: NoiseSuppressionStatusDataSource {

    public var _noiseSuppressionState = CurrentValueSubject<NoiseSuppressionState, Never>(.idle)

    public lazy var noiseSuppressionState: AnyPublisher<NoiseSuppressionState, Never> =
        _noiseSuppressionState.eraseToAnyPublisher()

    public func set(state: VERADomain.NoiseSuppressionState) {
        _noiseSuppressionState.value = state
    }
}
