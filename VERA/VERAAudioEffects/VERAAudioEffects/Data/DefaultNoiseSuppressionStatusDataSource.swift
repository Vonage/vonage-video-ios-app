//
//  Created by Vonage on 8/2/26.
//

import Combine
import VERADomain

public final class DefaultNoiseSuppressionStatusDataSource: NoiseSuppressionStatusDataSource {

    private let _noiseSuppressionState = CurrentValueRelay<NoiseSuppressionState, Never>(.disabled)
    public var noiseSuppressionState: AnyPublisher<NoiseSuppressionState, Never> {
        _noiseSuppressionState.publisher
    }

    public init() {}

    public func set(state: NoiseSuppressionState) {
        _noiseSuppressionState.send(state)
    }
}
