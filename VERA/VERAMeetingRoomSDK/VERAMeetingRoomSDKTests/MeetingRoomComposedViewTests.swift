//
//  Created by Vonage on 21/04/2026.
//

import Combine
import Foundation
import SwiftUI
import Testing
import UIKit
import VERADomain
import VERAMeetingRoom
import VERATestHelpers
import VERAVonage

@testable import VERAMeetingRoomSDK

@Suite("MeetingRoomComposedView tests")
struct MeetingRoomComposedViewTests {

    private static let testBaseURL = URL(string: "https://api.example.com")!

    // MARK: - Stored Properties

    @Test("MeetingRoomComposedView stores provided enabledFeatures")
    @MainActor
    func storesEnabledFeatures() {
        let features: Set<MeetingRoomFeature> = [.chat, .captions]
        let sut = makeSUT(enabledFeatures: features)
        #expect(sut.enabledFeatures == features)
    }

    @Test("MeetingRoomComposedView stores empty enabledFeatures when none provided")
    @MainActor
    func storesEmptyEnabledFeatures() {
        let sut = makeSUT(enabledFeatures: [])
        #expect(sut.enabledFeatures.isEmpty)
    }

    @Test("captionsButtonViewModel is nil when not provided")
    @MainActor
    func captionsButtonViewModelIsNilByDefault() {
        let sut = makeSUT()
        #expect(sut.captionsButtonViewModel == nil)
    }

    @Test("captionsViewModel is nil when not provided")
    @MainActor
    func captionsViewModelIsNilByDefault() {
        let sut = makeSUT()
        #expect(sut.captionsViewModel == nil)
    }

    @Test("floatingEmojisOverlayViewModel is nil when not provided")
    @MainActor
    func floatingEmojisOverlayViewModelIsNilByDefault() {
        let sut = makeSUT()
        #expect(sut.floatingEmojisOverlayViewModel == nil)
    }

    @Test("emojiPickerContainerViewModel is nil when not provided")
    @MainActor
    func emojiPickerContainerViewModelIsNilByDefault() {
        let sut = makeSUT()
        #expect(sut.emojiPickerContainerViewModel == nil)
    }

    @Test("statsOverlayViewModel is nil when not provided")
    @MainActor
    func statsOverlayViewModelIsNilByDefault() {
        let sut = makeSUT()
        #expect(sut.statsOverlayViewModel == nil)
    }

    // MARK: - Container Feature Reflection

    @Test("Container with chat feature reports chat as enabled")
    @MainActor
    func containerWithChatFeatureReportsChatEnabled() {
        let container = makeContainer(enabledFeatures: [.chat])
        let sut = makeSUT(enabledFeatures: [.chat], container: container)
        #expect(sut.container.isFeatureEnabled(.chat))
    }

    @Test("Container without chat feature reports chat as disabled")
    @MainActor
    func containerWithoutChatFeatureReportsChatDisabled() {
        let container = makeContainer(enabledFeatures: [])
        let sut = makeSUT(enabledFeatures: [], container: container)
        #expect(!sut.container.isFeatureEnabled(.chat))
    }

    // MARK: - onAppear Bindings

    @Test("onAppear sets buttonsAssembler.onShowChat callback")
    @MainActor
    func onAppearSetsOnShowChat() async {
        let (sut, assembler) = makeSUTWithAssembler()
        await renderView(sut)
        #expect(assembler.onShowChat != nil)
    }

    @Test("onAppear sets buttonsAssembler.onShowPickerView callback")
    @MainActor
    func onAppearSetsOnShowPickerView() async {
        let (sut, assembler) = makeSUTWithAssembler()
        await renderView(sut)
        #expect(assembler.onShowReactions != nil)
    }

    @Test("onAppear sets buttonsAssembler.onShowSettings callback")
    @MainActor
    func onAppearSetsOnShowSettings() async {
        let (sut, assembler) = makeSUTWithAssembler()
        await renderView(sut)
        #expect(assembler.onShowSettings != nil)
    }

    // MARK: - Helpers

    @MainActor
    private func makeSUT(
        enabledFeatures: Set<MeetingRoomFeature> = [],
        container: MeetingRoomSDKContainer? = nil
    ) -> MeetingRoomComposedView {
        let actualContainer = container ?? makeContainer(enabledFeatures: enabledFeatures)
        let assembler = BottomBarButtonsAssembler(container: actualContainer, enabledFeatures: enabledFeatures)
        let factory = makeMeetingRoomFactory()
        let viewModel = makeViewModel()
        return MeetingRoomComposedView(
            meetingRoomFactory: factory,
            viewModel: viewModel,
            container: actualContainer,
            pictureInPictureManager: PictureInPictureManager(),
            enabledFeatures: enabledFeatures,
            buttonsAssembler: assembler,
            onAction: { _ in },
            alertPresenter: .init(),
            captionsButtonViewModel: nil,
            captionsViewModel: nil,
            floatingEmojisOverlayViewModel: nil,
            emojiPickerContainerViewModel: nil,
            statsOverlayViewModel: nil
        )
    }

    @MainActor
    private func makeSUTWithAssembler(
        enabledFeatures: Set<MeetingRoomFeature> = []
    ) -> (MeetingRoomComposedView, BottomBarButtonsAssembler) {
        let container = makeContainer(enabledFeatures: enabledFeatures)
        let assembler = BottomBarButtonsAssembler(container: container, enabledFeatures: enabledFeatures)
        let factory = makeMeetingRoomFactory()
        let viewModel = makeViewModel()
        let view = MeetingRoomComposedView(
            meetingRoomFactory: factory,
            viewModel: viewModel,
            container: container,
            pictureInPictureManager: PictureInPictureManager(),
            enabledFeatures: enabledFeatures,
            buttonsAssembler: assembler,
            onAction: { _ in },
            alertPresenter: .init(),
            captionsButtonViewModel: nil,
            captionsViewModel: nil,
            floatingEmojisOverlayViewModel: nil,
            emojiPickerContainerViewModel: nil,
            statsOverlayViewModel: nil
        )
        return (view, assembler)
    }

    @MainActor
    private func renderView<V: View>(_ view: V) async {
        let hostingController = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        window.rootViewController = hostingController
        window.isHidden = false
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        await delay()
    }

    private func makeContainer(
        enabledFeatures: Set<MeetingRoomFeature>
    ) -> MeetingRoomSDKContainer {
        MeetingRoomSDKContainer(
            baseURL: Self.testBaseURL,
            enabledFeatures: enabledFeatures
        )
    }

    private func makeMeetingRoomFactory() -> MeetingRoomFactory {
        MeetingRoomFactory(
            baseURL: Self.testBaseURL,
            configuration: MeetingRoomConfiguration(),
            currentCallParticipantsRepository: makeMockCurrentCallParticipantsRepository(),
            sessionRepository: makeMockSessionRepository(),
            publisherRepository: makeMockVERAPublisherRepository(),
            roomCredentialsRepository: makeMockRoomCredentialsRepository(),
            captionsStatusDataSource: NullCaptionsStatusDataSource(),
            noiseSuppressionStatusDataSource: makeMockNoiseSuppressionStatusDataSource(),
            pinnedParticipantsDataSource: DefaultPinnedParticipantsDataSource(),
            sessionKeyHolder: DefaultSessionKeyHolder()
        )
    }

    @MainActor
    private func makeViewModel() -> MeetingRoomViewModel {
        MeetingRoomViewModel(
            roomName: "test-room",
            baseURL: Self.testBaseURL,
            connectToRoomUseCase: DefaultConnectToRoomUseCase(
                sessionRepository: makeMockSessionRepository(),
                roomCredentialsRepository: makeMockRoomCredentialsRepository(),
                sessionKeyWriter: DefaultSessionKeyHolder()
            ),
            disconnectRoomUseCase: DefaultDisconnectRoomUseCase(
                sessionRepository: makeMockSessionRepository()
            ),
            checkMicrophoneAuthorizationStatusUseCase: makeMockCheckMicrophoneAuthorizationStatusUseCase(),
            checkCameraAuthorizationStatusUseCase: makeMockCheckCameraAuthorizationStatusUseCase(),
            currentCallParticipantsRepository: makeMockCurrentCallParticipantsRepository(),
            captionsStatusDataSource: NullCaptionsStatusDataSource(),
            configuration: MeetingRoomConfiguration(),
            meetingRoomNavigation: MeetingRoomNavigation(actionHandler: { _ in }, roomName: "test-room"),
            getExternalButtons: { [] },
            externalButtonsUpdates: Empty().eraseToAnyPublisher(),
            noiseSuppressionStatusDataSource: makeMockNoiseSuppressionStatusDataSource(),
            pinnedParticipantsDataSource: DefaultPinnedParticipantsDataSource()
        )
    }
}
