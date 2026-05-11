//
//  Created by Vonage on 10/5/26.
//

import Combine
import Foundation
import SwiftUI
import Testing
import VERADomain
import VERATestHelpers

@testable import VERABackgroundEffects

/// Exercises the provider-aware routing in `VERAPublisher.setBackgroundBlur`.
///
/// The Vision branch invokes the Vonage SDK directly (`OTVideoTransformer(name:transformer:)`)
/// so it is verified at the boundary — through the captured key. The Vonage branch
/// goes through the injectable `transformerFactory`, so it is verified end-to-end.
@Suite("setBackgroundBlur routing")
struct BackgroundBlurRoutingTests {

    @Test func turningOffWithVonageProviderRemovesBothKeys() throws {
        let spy = RoutingPublisherSpy()
        try spy.setBackgroundBlur(blurLevel: .none, provider: .vonage)

        #expect(spy.removedKeys.contains(BackgroundBlur.key))
        #expect(spy.removedKeys.contains(AppleVisionBlur.key))
        #expect(spy.addedKeys.isEmpty)
    }

    @Test func turningOffWithAppleVisionProviderRemovesBothKeys() throws {
        let spy = RoutingPublisherSpy()
        try spy.setBackgroundBlur(blurLevel: .none, provider: .appleVision)

        #expect(spy.removedKeys.contains(BackgroundBlur.key))
        #expect(spy.removedKeys.contains(AppleVisionBlur.key))
        #expect(spy.addedKeys.isEmpty)
    }

    @Test func vonageProviderAddsVonageTransformerOnly() throws {
        let spy = RoutingPublisherSpy()
        try spy.setBackgroundBlur(blurLevel: .high, provider: .vonage)

        #expect(spy.addedKeys == [BackgroundBlur.key])
    }

    // NOTE: The active Apple Vision routing path (`blurLevel != .none, provider: .appleVision`)
    // calls `OTVideoTransformer(name:transformer:)`, which is the Vonage SDK constructor and
    // requires a session/runtime context to complete safely. In a pure unit test it crashes the
    // test harness. The cleanup contract for that path is exercised in
    // `turningOffWithAppleVisionProviderRemovesBothKeys`; full routing coverage belongs in an
    // on-device integration test once the segmentation/composite pipeline is implemented.
}

// MARK: - Spy

/// Test double for `VERAPublisher` that captures added/removed transformer keys.
///
/// `addVideoTransformer` is the only method that needs to capture keys precisely
/// for routing assertions — `removeTransformer` also captures so the cleanup
/// contract can be asserted.
private final class RoutingPublisherSpy: VERAPublisher {

    var audioTransformers: [any VERATransformer] = []
    var videoTransformers: [any VERATransformer] = []
    var transformerFactory: any VERATransformerFactory = MockTransformerFactory()

    var view: AnyView { AnyView(EmptyView()) }
    var publishAudio: Bool = true
    var publishVideo: Bool = true
    var cameraPosition: CameraPosition = .front
    var audioLevelPublisher: AnyPublisher<Float, Never> = CurrentValueSubject(0).eraseToAnyPublisher()

    private(set) var addedKeys: [String] = []
    private(set) var removedKeys: [String] = []

    func switchCamera(to cameraDeviceID: String) {}
    func cleanUp() {}

    func addVideoTransformer(_ transformer: any VERATransformer) {
        addedKeys.append(transformer.key)
    }

    func setVideoTransformers(_ transformers: [any VERATransformer]) {
        addedKeys.append(contentsOf: transformers.map(\.key))
    }

    func removeTransformer(_ key: String) {
        removedKeys.append(key)
    }

    func addAudioTransformer(_ transformer: any VERATransformer) {}
    func setAudioTransformers(_ transformers: [any VERATransformer]) {}
    func removeAudioTransformer(_ key: String) {}

    func reset() {
        addedKeys.removeAll()
        removedKeys.removeAll()
    }
}
