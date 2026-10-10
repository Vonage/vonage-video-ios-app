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

    // Simulator runs exercise the selected-camera policy with the SDK demo video.
    // Physical camera orientation still requires device validation.
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

    @Test("Mirror preference updates local rendering without changing capture or publisher media")
    func mirrorPreferenceKeepsPublisherAndCaptureAttached() {
        let sut = makeSUT()
        sut.setup()
        let capture = sut.otPublisher.videoCapture
        let publishAudio = sut.publishAudio
        let publishVideo = sut.publishVideo

        sut.selfViewMirroringEnabled = false
        #expect(!sut.inlineVideoRenderer.isMirrored)
        sut.selfViewMirroringEnabled = true
        #expect(sut.inlineVideoRenderer.isMirrored == (sut.cameraPosition == .front))
        #expect(sut.otPublisher.videoCapture === capture)
        #expect(sut.otPublisher.videoRender === sut.inlineVideoRenderer)
        #expect(sut.publishAudio == publishAudio)
        #expect(sut.publishVideo == publishVideo)
    }

    @Test("Rear-camera preview remains unmirrored and switching to front restores the saved mirror setting")
    func cameraAndMirrorSelectionStayConsistent() {
        let sut = makeSUT()
        sut.setup()
        sut.cameraPosition = .back
        #expect(!sut.inlineVideoRenderer.isMirrored)
        sut.cameraPosition = .front
        #expect(sut.inlineVideoRenderer.isMirrored == (sut.cameraPosition == .front))
        sut.selfViewMirroringEnabled = false
        #expect(!sut.inlineVideoRenderer.isMirrored)
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
