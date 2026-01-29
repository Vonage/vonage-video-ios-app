//
//  Created by Vonage on 16/7/25.
//

import Foundation
import SwiftUI
import VERADomain

public final class MockVERAPublisher: VERAPublisher {
    public var view: AnyView

    public var publishAudio: Bool

    public var publishVideo: Bool

    public var cameraPosition: CameraPosition

    public var didCallCleanUp: Bool = false

    public init(
        view: AnyView = AnyView(Color.red),
        publishAudio: Bool = true,
        publishVideo: Bool = true,
        cameraPosition: CameraPosition = .front
    ) {
        self.view = view
        self.publishAudio = publishAudio
        self.publishVideo = publishVideo
        self.cameraPosition = cameraPosition
    }

    public func switchCamera(to cameraDeviceID: String) {
    }

    public func cleanUp() {
        didCallCleanUp = true
    }
}
