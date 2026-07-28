//
//  Created by Vonage on 14/7/26.
//

import Foundation
import OpenTok
import Testing

@testable import VERAVonage

@Suite("PictureInPictureVonagePublisher tests")
@MainActor
struct PictureInPictureVonagePublisherTests {

    private func makeSUT() -> PictureInPictureVonagePublisher {
        PictureInPictureVonagePublisher(
            publisher: OTPublisher(delegate: nil)!,
            transformerFactory: VonageTransformerFactory(),
            initialDimensions: .zero)
    }

    @Test("Exposes a permanent inline renderer")
    func hasInlineRenderer() {
        let sut = makeSUT()
        #expect(sut.inlineVideoRenderer.renderedFrameCount == 0)
    }

    @Test("The view getter is safe before and after setup")
    func viewGetter() {
        let sut = makeSUT()
        _ = sut.view  // not-attached branch → SDK view
        sut.setup()
        _ = sut.view  // attached branch → renderer view
    }

    @Test("setup attaches the renderer as the publisher's videoRender")
    func setupAttachesRenderer() {
        let sut = makeSUT()
        sut.setup()
        #expect(sut.otPublisher.videoRender === sut.inlineVideoRenderer)
    }

    // The camera position doesn't stick without a real camera (simulator), so these exercise the
    // camera-change → mirroring-update paths for coverage; the renderer stays attached throughout.
    @Test("Changing the camera position keeps the renderer attached")
    func cameraPositionChangeKeepsRendererAttached() {
        let sut = makeSUT()
        sut.setup()
        sut.cameraPosition = .front
        sut.cameraPosition = .back
        #expect(sut.otPublisher.videoRender === sut.inlineVideoRenderer)
    }

    @Test("switchCamera keeps the renderer attached")
    func switchCameraKeepsRendererAttached() {
        let sut = makeSUT()
        sut.setup()
        sut.switchCamera(to: VonageCameraDevice.front.rawValue)
        sut.switchCamera(to: VonageCameraDevice.back.rawValue)
        #expect(sut.otPublisher.videoRender === sut.inlineVideoRenderer)
    }

    @Test("cleanUp detaches the renderer")
    func cleanUpDetaches() {
        let sut = makeSUT()
        sut.setup()
        sut.cleanUp()
        #expect(sut.otPublisher.videoRender == nil)
    }

    @Test("detachInlineRenderer before setup is a no-op")
    func detachBeforeSetupIsNoOp() {
        let sut = makeSUT()
        sut.detachInlineRenderer()
        #expect(sut.inlineVideoRenderer.renderedFrameCount == 0)
    }
}
