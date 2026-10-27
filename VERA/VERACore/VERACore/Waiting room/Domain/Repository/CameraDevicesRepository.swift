//
//  Created by Vonage on 16/7/25.
//

import Combine
import Foundation

@MainActor
public protocol CameraDevicesRepository: Sendable {
    var observeAvailableDevices: AnyPublisher<[CameraDevice], Never> { get }
}
