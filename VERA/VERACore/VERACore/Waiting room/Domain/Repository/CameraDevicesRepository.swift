//
//  Created by Vonage on 16/7/25.
//

import Combine
import Foundation

public protocol CameraDevicesRepository {
    var observeAvailableDevices: AnyPublisher<[CameraDevice], Never> { get }

    func routeTo(_ cameraDeviceID: String)
}
