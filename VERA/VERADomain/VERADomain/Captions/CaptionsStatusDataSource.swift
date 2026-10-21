//
//  Created by Vonage on 6/2/26.
//

import Combine
import Foundation

public protocol CaptionsStatusDataSource {
    var captionsState: AnyPublisher<CaptionsState, Never> { get }
    func set(captionsState: CaptionsState)
    func reset()
}
