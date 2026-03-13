//
//  Created by Vonage on 8/2/26.
//

import Combine
import VERADomain

public final class DefaultNoiseSuppressionStatusDataSource: NoiseSuppressionStatusDataSource, @unchecked Sendable {

    private var _noiseSuppressionState = CurrentValueSubject<NoiseSuppressionState, Never>(.disabled)
    public lazy var noiseSuppressionState: AnyPublisher<NoiseSuppressionState, Never> =
        _noiseSuppressionState.eraseToAnyPublisher()

    public init() {}

    public func set(state: NoiseSuppressionState) {
        _noiseSuppressionState.value = state
    }
}
