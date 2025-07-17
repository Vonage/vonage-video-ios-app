//
//  Created by Vonage on 17/7/25.
//

import Foundation
import SwiftUI
import VERACore

final class MockVERAPublisher: VERACore.VERAPublisher {
    var view: AnyView

    var publishAudio: Bool

    var publishVideo: Bool

    var cameraPosition: VERACore.CameraPosition

    init(
        view: AnyView = AnyView(EmptyView()),
        publishAudio: Bool = true,
        publishVideo: Bool = true,
        cameraPosition: VERACore.CameraPosition = .front
    ) {
        self.view = view
        self.publishAudio = publishAudio
        self.publishVideo = publishVideo
        self.cameraPosition = cameraPosition
    }
}
