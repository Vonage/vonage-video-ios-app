//
//  Created by Vonage on 16/7/25.
//

import Foundation
import SwiftUI
import VERACore

public final class MockVERAPublisher: VERAPublisher {
    public var view: AnyView

    public var publishAudio: Bool

    public var publishVideo: Bool

    public var cameraPosition: VERACore.CameraPosition

    public var didCallCleanUp: Bool = false

    public init(
        view: AnyView = AnyView(Color.red),
        publishAudio: Bool = true,
        publishVideo: Bool = true,
        cameraPosition: VERACore.CameraPosition = .front
    ) {
        self.view = view
        self.publishAudio = publishAudio
        self.publishVideo = publishVideo
        self.cameraPosition = cameraPosition
    }

    public func routeTo(_ cameraDeviceID: String) async {
    }

    public func cleanUp() {
        didCallCleanUp = true
    }
}
