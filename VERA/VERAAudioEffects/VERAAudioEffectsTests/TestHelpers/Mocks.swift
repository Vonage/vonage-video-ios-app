//
//  Created by Vonage on 13/03/2026.
//

import Combine
import SwiftUI
import VERADomain
import VERATestHelpers

final class NoiseSuppressionStatusDataSourceSpy: NoiseSuppressionStatusDataSource {
    private let _noiseSuppressionState = PassthroughSubject<NoiseSuppressionState, Never>()
    var noiseSuppressionState: AnyPublisher<NoiseSuppressionState, Never> {
        _noiseSuppressionState.eraseToAnyPublisher()
    }

    var setState_callCount = 0
    var setState_lastValue: NoiseSuppressionState?
    private let shouldThrowError: Bool

    public init(shouldThrowError: Bool = false) {
        self.shouldThrowError = shouldThrowError
    }

    func set(state: NoiseSuppressionState) {
        guard !shouldThrowError else { return }

        setState_callCount += 1
        setState_lastValue = state
        _noiseSuppressionState.send(state)
    }
}

final class NoiseSuppressionPublisherSpy: VERAPublisher {
    var audioTransformers: [any VERATransformer] = []
    var transformerFactory: any VERATransformerFactory
    var view: AnyView { AnyView(EmptyView()) }
    var videoTransformers: [any VERATransformer] = []
    var publishAudio: Bool = true
    var publishVideo: Bool = true
    var cameraPosition: CameraPosition = .front

    var setNoiseSuppression_callCount = 0
    private let shouldThrowError: Bool

    init(
        transformerFactory: VERATransformerFactory = MockTransformerFactory(),
        shouldThrowError: Bool = false
    ) {
        self.transformerFactory = transformerFactory
        self.shouldThrowError = shouldThrowError
    }

    func addVideoTransformer(_ transformer: any VERATransformer) {}
    func setVideoTransformers(_ transformers: [any VERATransformer]) {}
    func removeTransformer(_ key: String) {}

    func addAudioTransformer(_ transformer: any VERATransformer) {
        if !shouldThrowError {
            setNoiseSuppression_callCount += 1
        }
    }

    func setAudioTransformers(_ transformers: [any VERATransformer]) {}
    func removeAudioTransformer(_ key: String) {}
    func switchCamera(to cameraDeviceID: String) {}
    func cleanUp() {}
}
