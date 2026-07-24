//
//  Created by Vonage on 14/7/26.
//

import Foundation
import OpenTok
import Testing
import VERADomain

@testable import VERAVonage

@Suite("VonagePublisherFactory tests")
@MainActor
struct VonagePublisherFactoryTests {

    private func makeBaseFactory() -> VonagePublisherFactory {
        VonagePublisherFactory(
            checkCameraAuthorizationStatusUseCase: DefaultCheckCameraAuthorizationStatusUseCase(),
            checkMicrophoneAuthorizationStatusUseCase: DefaultCheckMicrophoneAuthorizationStatusUseCase())
    }

    private func makePiPFactory() -> PictureInPictureVonagePublisherFactory {
        PictureInPictureVonagePublisherFactory(
            checkCameraAuthorizationStatusUseCase: DefaultCheckCameraAuthorizationStatusUseCase(),
            checkMicrophoneAuthorizationStatusUseCase: DefaultCheckMicrophoneAuthorizationStatusUseCase())
    }

    @Test("Base factory makes a native (non-PiP) publisher")
    func baseFactoryMakesNative() throws {
        let publisher = try makeBaseFactory().make(PublisherSettings())

        #expect(publisher is VonagePublisher)
        #expect(!(publisher is PictureInPictureVonagePublisher))
    }

    @Test("PiP factory makes a PiP-capable publisher")
    func pipFactoryMakesPiP() throws {
        let publisher = try makePiPFactory().make(PublisherSettings())

        #expect(publisher is PictureInPictureVonagePublisher)
    }

    @Test("Factory honors publisher settings")
    func factoryHonorsSettings() throws {
        let settings = PublisherSettings(username: "Zaphod", publishAudio: false, publishVideo: false)
        let publisher = try makeBaseFactory().make(settings)

        #expect(publisher is VonagePublisher)
    }
}
