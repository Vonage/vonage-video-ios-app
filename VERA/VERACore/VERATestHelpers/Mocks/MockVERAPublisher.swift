//
//  Created by Vonage on 16/7/25.
//

import Foundation
import SwiftUI
import VERADomain

public final class MockVERAPublisher: VERAPublisher {
    public var audioTransformers: [any VERATransformer] = []

    public var videoTransformers: [any VERATransformer] = []

    public var transformerFactory: any VERATransformerFactory

    public var view: AnyView

    public var publishAudio: Bool

    public var publishVideo: Bool

    public var cameraPosition: CameraPosition

    public var didCallCleanUp: Bool = false

    public init(
        view: AnyView = AnyView(Color.red),
        publishAudio: Bool = true,
        publishVideo: Bool = true,
        cameraPosition: CameraPosition = .front,
        transformerFactory: any VERATransformerFactory = MockTransformerFactory()
    ) {
        self.view = view
        self.publishAudio = publishAudio
        self.publishVideo = publishVideo
        self.cameraPosition = cameraPosition
        self.transformerFactory = transformerFactory
    }

    public func switchCamera(to cameraDeviceID: String) {
    }

    public func cleanUp() {
        didCallCleanUp = true
    }

    public func addVideoTransformer(_ transformer: any VERADomain.VERATransformer) {
    }

    public func setVideoTransformers(_ transformers: [any VERADomain.VERATransformer]) {
    }

    public func removeTransformer(_ key: String) {
    }
    public func addAudioTransformer(_ transformer: any VERATransformer) {
    }

    public func setAudioTransformers(_ transformers: [any VERATransformer]) {
    }

    public func removeAudioTransformer(_ key: String) {
    }
}

public final class MockTransformer: VERATransformer {
    public var key: String
    public var transformer: AnyObject

    public init(
        key: String = "anyKey",
        transformer: AnyObject
    ) {
        self.key = key
        self.transformer = transformer
    }
}

public final class MockTransformerFactory: VERATransformerFactory {
    public init() {}

    public func makeVideoTransformer(
        for key: String,
        params: String
    ) throws -> any VERADomain.VERATransformer {
        MockTransformer(key: key, transformer: NSObject())
    }

    public func makeAudioTransformer(for key: String, params: String) throws -> any VERATransformer {
        MockTransformer(key: key, transformer: NSObject())
    }
}
