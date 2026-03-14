//
//  Created by Vonage on 11/2/26.
//

import Combine

public final class NullNoiseSuppressionStatusDataSource: NoiseSuppressionStatusDataSource {

    public var noiseSuppressionState: AnyPublisher<NoiseSuppressionState, Never> = CurrentValueSubject(.disabled)
        .eraseToAnyPublisher()

    public init() {}

    public func set(state: NoiseSuppressionState) {}
}
