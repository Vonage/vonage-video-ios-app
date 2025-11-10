//
//  Created by Vonage on 16/7/25.
//

import SwiftUI

public enum CameraPosition {
    case front, back
}

public protocol VERAPublisher: AnyObject {
    var view: AnyView { get }
    var publishAudio: Bool { get set }
    var publishVideo: Bool { get set }
    var cameraPosition: CameraPosition { get set }

    func switchCamera(to cameraDeviceID: String)

    // Clean up resources
    func cleanUp()
}
