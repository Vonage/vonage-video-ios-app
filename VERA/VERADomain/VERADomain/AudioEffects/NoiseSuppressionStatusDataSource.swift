//
//  Created by Vonage on 6/2/26.
//

import Combine
import Foundation

public protocol NoiseSuppressionStatusDataSource {
    var noiseSuppressionState: AnyPublisher<NoiseSuppressionState, Never> { get }
    func set(state: NoiseSuppressionState)
}
