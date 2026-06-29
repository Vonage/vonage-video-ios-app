//
//  Created by Vonage on 29/6/26.
//

import Foundation
import OpenTok
import Testing
import UIKit
import VERACore
import VERADomain
import VERATestHelpers

@testable import VERAVonage

@Suite("PictureInPictureManager tests")
@MainActor
struct PictureInPictureManagerTests {

    // MARK: - Initial State

    @Test("Initial state has PiP inactive and no target")
    func initialState() {
        let sut = PictureInPictureManager()

        #expect(sut.isInPictureInPicture == false)
        #expect(sut.canStartPictureInPicture == false)
        #expect(sut.pipTargetParticipantId == nil)
    }

    // MARK: - requestPictureInPicture

    @Test("requestPictureInPicture without a target does not start PiP")
    func requestPipWithoutTarget() {
        let sut = PictureInPictureManager()

        sut.requestPictureInPicture()

        #expect(sut.isInPictureInPicture == false)
    }

    // MARK: - startPictureInPictureIfPossible

    @Test("startPictureInPictureIfPossible without a target is a no-op")
    func startPipWithoutTarget() {
        let sut = PictureInPictureManager()

        sut.startPictureInPictureIfPossible()

        #expect(sut.isInPictureInPicture == false)
        #expect(sut.canStartPictureInPicture == false)
    }

    // MARK: - configurePictureInPicture

    @Test("configurePictureInPicture with zero-size frame is a no-op")
    func configureWithZeroFrame() {
        let sut = PictureInPictureManager()
        let view = UIView()

        sut.configurePictureInPicture(sourceView: view, videoFrame: .zero)

        #expect(sut.canStartPictureInPicture == false)
    }

    @Test("configurePictureInPicture with 1x1 frame is a no-op")
    func configureWithTinyFrame() {
        let sut = PictureInPictureManager()
        let view = UIView()

        sut.configurePictureInPicture(sourceView: view, videoFrame: CGRect(x: 0, y: 0, width: 1, height: 1))

        #expect(sut.canStartPictureInPicture == false)
    }

    // MARK: - tearDown

    @Test("tearDown resets all published state")
    func tearDownResetsState() {
        let sut = PictureInPictureManager()
        sut.requestPictureInPicture()

        sut.tearDown()

        #expect(sut.isInPictureInPicture == false)
        #expect(sut.canStartPictureInPicture == false)
        #expect(sut.pipTargetParticipantId == nil)
    }

    @Test("tearDown can be called multiple times safely")
    func tearDownIdempotent() {
        let sut = PictureInPictureManager()

        sut.tearDown()
        sut.tearDown()

        #expect(sut.isInPictureInPicture == false)
    }

    // MARK: - bind

    @Test("bind to same call twice is idempotent")
    func bindIdempotent() {
        let sut = PictureInPictureManager()
        let call = makeSUT()

        sut.bind(to: call)
        sut.bind(to: call)

        sut.tearDown()
        #expect(sut.pipTargetParticipantId == nil)
    }
}

// MARK: - Helpers


@MainActor
private func makeSUT() -> VonageCall {
    VonageCall(
        credentials: makeMockCredentials(),
        session: VonageSessionSpy(),
        publisher: VonagePublisherSpy(),
        publisherRepository: MockPublisherRepository(),
        statsCollector: MockStatsCollector()
    )
}
