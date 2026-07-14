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

@Suite("PictureInPictureSessionOrchestrator tests")
@MainActor
struct PictureInPictureOrchestratorTests {

    // MARK: - Initial State

    @Test("Initial state has PiP inactive and no target")
    func initialState() {
        let sut = PictureInPictureSessionOrchestrator()

        #expect(sut.isInPictureInPicture == false)
        #expect(sut.canStartPictureInPicture == false)
        #expect(sut.pipTargetParticipantId == nil)
    }

    // MARK: - requestPictureInPicture

    @Test("requestPictureInPicture without a target does not start PiP")
    func requestPipWithoutTarget() {
        let sut = PictureInPictureSessionOrchestrator()

        sut.requestPictureInPicture()

        #expect(sut.isInPictureInPicture == false)
    }

    // MARK: - tearDown

    @Test("tearDown resets all published state")
    func tearDownResetsState() {
        let sut = PictureInPictureSessionOrchestrator()
        sut.requestPictureInPicture()

        sut.tearDown()

        #expect(sut.isInPictureInPicture == false)
        #expect(sut.canStartPictureInPicture == false)
        #expect(sut.pipTargetParticipantId == nil)
    }

    @Test("tearDown can be called multiple times safely")
    func tearDownIdempotent() {
        let sut = PictureInPictureSessionOrchestrator()

        sut.tearDown()
        sut.tearDown()

        #expect(sut.isInPictureInPicture == false)
    }

    // MARK: - bind

    @Test("bind to same call twice is idempotent")
    func bindIdempotent() {
        let sut = PictureInPictureSessionOrchestrator()
        let call = makeSUT()

        sut.bind(to: call)
        sut.bind(to: call)

        sut.tearDown()
        #expect(sut.pipTargetParticipantId == nil)
    }

    // MARK: - Anchoring & lifecycle

    @Test("bind, register anchor, request and stop run end-to-end")
    func fullLifecycleRuns() {
        let sut = PictureInPictureSessionOrchestrator()
        let call = makeSUT()

        sut.bind(to: call)
        sut.registerAnchor(sourceView: UIView(), videoFrame: CGRect(x: 0, y: 0, width: 160, height: 90))
        sut.requestPictureInPicture()
        sut.stopPictureInPicture()
        sut.tearDown()

        #expect(sut.isInPictureInPicture == false)
    }

    @Test("registerAnchor before bind is safe")
    func registerAnchorBeforeBind() {
        let sut = PictureInPictureSessionOrchestrator()

        sut.registerAnchor(sourceView: UIView(), videoFrame: .zero)

        #expect(sut.canStartPictureInPicture == false)
    }

    @Test("stopPictureInPicture when inactive is safe")
    func stopWhenInactive() {
        let sut = PictureInPictureSessionOrchestrator()

        sut.stopPictureInPicture()

        #expect(sut.isInPictureInPicture == false)
    }

    @Test("Re-registering the same anchor does not reconfigure")
    func reRegisterSameAnchorIdempotent() {
        let sut = PictureInPictureSessionOrchestrator()
        let call = makeSUT()
        let anchor = UIView()

        sut.bind(to: call)
        sut.registerAnchor(sourceView: anchor, videoFrame: .zero)
        sut.registerAnchor(sourceView: anchor, videoFrame: .zero)

        #expect(sut.isInPictureInPicture == false)
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
