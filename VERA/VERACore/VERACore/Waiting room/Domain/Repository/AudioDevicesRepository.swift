//
//  Created by Vonage on 15/7/25.
//

import Combine
import Foundation

public protocol AudioDevicesRepository {
    var observeAvailableDevices: AnyPublisher<[AudioDevice], Never> { get }

    func routeTo(_ audioDeviceID: String) throws
}
