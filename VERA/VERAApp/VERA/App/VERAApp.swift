//
//  Created by Vonage on 4/7/25.
//

import Combine
import Foundation
import SwiftUI
import VERACommonUI
import VERACore
import VERADomain
import VERAVonage

#if CHAT_ENABLED
    import VERAChat
#endif

#if ARCHIVING_ENABLED
    import VERAArchiving
#endif

#if BACKGROUND_EFFECTS_ENABLED
    import VERABackgroundEffects
#endif

#if CAPTIONS_ENABLED
    import VERACaptions
#endif

#if REACTIONS_ENABLED
    import VERAReactions
#endif

// MARK: - Constants

/// Layout constants for the VERA application.
///
/// Contains computed values that depend on other module constants
/// to ensure consistent spacing and positioning across the app.
private enum VERAAppConstants {
    /// Padding for overlays positioned above the bottom bar.
    ///
    /// Calculated as the total bottom bar height plus a small gap
    /// to visually separate overlay content from the bar.
    static var overlayBottomPadding: CGFloat {
        BottomBarConstants.totalHeight + 4
    }
}

@main
struct VERAApp: App {
    @StateObject var navigationCoordinator = NavigationCoordinator()
    let dependencyContainer = DependencyContainer()

    var handleUniversalLink: HandleUniversalLink {
        HandleUniversalLink(
            baseURL: dependencyContainer.baseURL,
            navigator: navigationCoordinator)
    }

    @State private var previousPath = NavigationPath()
    @State private var showChat = false
    @State private var showPickerView = false
    @State private var showCaptions = false

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationCoordinator.path) {
                makeLandingPage()
                    .navigationDestination(for: AppRoute.self) { destination in
                        switch destination {
                        case .waitingRoom(let roomName):
                            if navigationCoordinator.isInMeeting {
                                LoaderModalView()
                            } else {
                                makeWaitingRoom(roomName: roomName)
                            }
                        case .goodbye(let roomName):
                            makeGoodbyePage(roomName: roomName)
                        case .meetingRoom:
                            fatalError("Should not be able to navigate to meeting room from landing")
                        case .landing:
                            fatalError("Should not be able to navigate to landing")
                        case .settings:
                            fatalError("Should not be able to navigate to settings")
                        }
                    }
            }
            .fullScreenCover(isPresented: $navigationCoordinator.isInMeeting) {
                if let currentRoom = navigationCoordinator.currentMeetingRoom {
                    makeMeetingRoom(roomName: currentRoom)
                        .onDisappear {
                            dependencyContainer.publisherRepository.resetPublisher()
                            #if ARCHIVING_ENABLED
                                Task {
                                    await navigationCoordinator.archivesViewModel?.loadData()
                                }
                            #endif
                        }
                    
                        #if CHAT_ENABLED
                            .sheet(isPresented: $showChat) {
                                makeChatView()
                            }
                        #endif
                    
                        #if REACTIONS_ENABLED
                            .dismissibleOverlay(
                                isPresented: $showPickerView,
                                alignment: .bottom,
                                edgePadding: VERAAppConstants.overlayBottomPadding
                            ) {
                                makePickerView()
                            }
                            .overlay {
                                makeFloatingEmojisOverlay()
                            }
                        #endif
                    
                        #if CAPTIONS_ENABLED
                            .onReceive(
                                navigationCoordinator.captionsButtonViewModel?.$state
                                .eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
                            ) { state in
                                showCaptions = state.captionsEnabled
                            }
                            .dismissibleOverlay(
                                isPresented: $showCaptions,
                                alignment: .bottom,
                                edgePadding: VERAAppConstants.overlayBottomPadding,
                                allowsHitTesting: false
                            ) {
                                makeCaptionsView()
                            }
                        #endif
                }
            }
            .environmentObject(navigationCoordinator)
            .alert(item: $navigationCoordinator.alertItem) { $0.view }
            .onOpenURL { url in
                handleUniversalLink(url)
            }
            .tint(VERACommonUIAsset.SemanticColors.primary.swiftUIColor)
        }
    }

    // MARK: - Factory Methods

    var landingPageFactory: LandingPageFactory { dependencyContainer.landingPageFactory }
    var waitingRoomFactory: WaitingRoomFactory { dependencyContainer.waitingRoomFactory }
    var meetingRoomFactory: MeetingRoomFactory { dependencyContainer.meetingRoomFactory }
    var goodByePageFactory: GoodByePageFactory { dependencyContainer.goodByePageFactory }

    #if CHAT_ENABLED
        var chatFactory: ChatFactory { dependencyContainer.chatFactory }
    #endif

    #if ARCHIVING_ENABLED
        var archiveFactory: ArchivingFactory { dependencyContainer.archivingFactory }
    #endif

    #if BACKGROUND_EFFECTS_ENABLED
        var backgroundBlurFactory: BackgroundBlurFactory { dependencyContainer.backgroundBlurFactory }
    #endif

    #if CAPTIONS_ENABLED
        var captionsFactory: CaptionsFactory { dependencyContainer.captionsFactory }
    #endif

    private func makeLandingPage() -> some View {
        landingPageFactory.make { roomName in
            navigationCoordinator.go(to: .waitingRoom(roomName))
        }
    }

    private func makeWaitingRoom(roomName: String) -> some View {
        var waitingRoomViewModel: WaitingRoomViewModel

        if let existingViewModel = navigationCoordinator.waitingRoomViewModel,
            existingViewModel.roomName == roomName
        {
            // Reuse existing view model for the same room
            waitingRoomViewModel = existingViewModel
        } else {
            // Create a new waiting room view and view model for the specified room
            let result = waitingRoomFactory.make(roomName: roomName) {
                switch $0 {
                case .presentAlert(let alertItem):
                    navigationCoordinator.showAlert(alertItem)
                case .navigateToSettings:
                    navigationCoordinator.go(to: .settings)
                case .navigateToMeetingRoom(let roomName):
                    navigationCoordinator.go(to: .meetingRoom(roomName))
                default: break
                }
            }
            waitingRoomViewModel = result.viewModel
            waitingRoomViewModel.extraTrailingButtons = makeWaitingRoomTrailingButtons()
            navigationCoordinator.waitingRoomViewModel = waitingRoomViewModel
        }

        return waitingRoomFactory.make(viewModel: waitingRoomViewModel)
            .onDisappear {
                // Required if the user goes back to the landing page
                dependencyContainer.cameraPreviewProviderRepository.resetPublisher()
                // Clear view model when leaving the waiting room
                navigationCoordinator.waitingRoomViewModel = nil
            }
    }

    private func makeWaitingRoomTrailingButtons() -> [ViewHolder] {
        #if BACKGROUND_EFFECTS_ENABLED
            let (_, viewModel) = backgroundBlurFactory.makeBlurButton(
                getCurrentPublisher: dependencyContainer.cameraPreviewProviderRepository.getPublisher
            )
            navigationCoordinator.backgroundBlurButtonViewModel = viewModel

            let view = backgroundBlurFactory.makeBlurButton(
                viewModel: navigationCoordinator.backgroundBlurButtonViewModel!
            )

            return [ViewHolder(id: "Blur", content: { view })]
        #else
            return []
        #endif
    }

    private func makeMeetingRoom(roomName: String) -> some View {
        let viewModel: MeetingRoomViewModel

        if let existingViewModel = navigationCoordinator.meetingRoomViewModel,
            existingViewModel.roomName == roomName
        {
            viewModel = existingViewModel
        } else {
            #if BACKGROUND_EFFECTS_ENABLED
                // Copy the current blur level from the waiting room
                // and apply it to the meeting room blur view model
                // the publisher repositories are different
                let (_, meetingRoomBlurViewModel) = backgroundBlurFactory.makeBlurButton(
                    getCurrentPublisher: dependencyContainer.publisherRepository.getPublisher
                )

                if let blurViewModel = navigationCoordinator.backgroundBlurButtonViewModel {
                    meetingRoomBlurViewModel.currentBlurLevel = blurViewModel.currentBlurLevel
                }
                navigationCoordinator.backgroundBlurButtonViewModel = meetingRoomBlurViewModel

            #endif

            #if ARCHIVING_ENABLED
                let (_, archiveButtonViewModel) = archiveFactory.makeArchivingButton(
                    roomName: roomName,
                    showAlert: { [weak navigationCoordinator] alertItem in
                        navigationCoordinator?.showAlert(alertItem)
                    }
                )
                archiveButtonViewModel.setup()
            #endif

            let (_, newViewModel) = meetingRoomFactory.make(
                roomName: roomName,
                getExternalButtons: getBottomBarButtons,
                onActionHandler: {
                    switch $0 {
                    case .presentAlert(let alertItem): navigationCoordinator.showAlert(alertItem)
                    case .navigateToGoodbye:
                        navigationCoordinator.go(to: .goodbye(roomName))
                    case .navigateToSettings:
                        navigationCoordinator.go(to: .settings)
                    case .navigateToWaitingRoom(let roomName):
                        navigationCoordinator.go(to: .waitingRoom(roomName))
                    default: break
                    }
                }
            )

            #if CAPTIONS_ENABLED
                let (_, captionsButtonViewModel) = captionsFactory.makeCaptionsButton(roomName: roomName)
                captionsButtonViewModel.setup()
                navigationCoordinator.captionsButtonViewModel = captionsButtonViewModel

                let (_, captionsViewModel) = captionsFactory.makeCaptionsView()
                navigationCoordinator.captionsViewModel = captionsViewModel
            #endif

            newViewModel.extraTopTrailingButtons = MeetingRoomTopTrailingButtons.topTrailingButtons
            navigationCoordinator.meetingRoomViewModel = newViewModel
            
            #if ARCHIVING_ENABLED
                navigationCoordinator.archiveButtonViewModel = archiveButtonViewModel
            #endif

            #if REACTIONS_ENABLED
                navigationCoordinator.emojiButtonContainerViewModel =
                    dependencyContainer.reactionsFactory.makeEmojiButton().viewModel
                navigationCoordinator.floatingEmojisOverlayViewModel =
                    dependencyContainer.reactionsFactory.makeFloatingEmojisOverlay().viewModel
            #endif
            
            viewModel = newViewModel
        }

        return meetingRoomFactory.make(viewModel: viewModel)
            .onDisappear {
                // Clear view model when leaving the meeting room
                navigationCoordinator.meetingRoomViewModel = nil
            }
    }

    private func getBottomBarButtons(
        _ state: MeetingRoomButtonsState
    ) -> [BottomBarButton] {
        var extraButtons: [BottomBarButton] = []
        #if CHAT_ENABLED
            extraButtons.append(
                dependencyContainer.mapToChatBottomBarButton {
                    showChat = true
                }
            )
        #endif

        #if BACKGROUND_EFFECTS_ENABLED
            if let backgroundBlurButtonViewModel = navigationCoordinator.backgroundBlurButtonViewModel {
                extraButtons.append(
                    dependencyContainer.makeBackgroundEffectsButton(backgroundBlurButtonViewModel)
                )
            }

        #endif

        #if ARCHIVING_ENABLED
            if let archiveButtonViewModel = navigationCoordinator.archiveButtonViewModel {
                extraButtons.append(dependencyContainer.mapToArchiveBottomBarButton(archiveButtonViewModel, state))
            }
        #endif

        #if CAPTIONS_ENABLED
            if let captionsButtonViewModel = navigationCoordinator.captionsButtonViewModel {
                extraButtons.append(dependencyContainer.makeCaptionsButton(captionsButtonViewModel))
            }
        #endif
        
        #if REACTIONS_ENABLED
            if let viewModel = navigationCoordinator.emojiButtonContainerViewModel {
                extraButtons.append(
                    dependencyContainer.mapToReactionsBottomBarButton(viewModel) {
                        showPickerView = true
                    }
                )
            }
        #endif
        return extraButtons
    }

    private func getExtraOverlays(
        _ state: MeetingRoomOverlayState
    ) -> [ViewGenerator] {
        []
    }

    private func makeGoodbyePage(roomName: String) -> some View {
        let viewModel: GoodByeViewModel

        if let existingViewModel = navigationCoordinator.goodByeViewModel, existingViewModel.roomName == roomName {
            viewModel = existingViewModel
        } else {
            let (_, newViewModel) = goodByePageFactory.make(roomName: roomName) {
                navigationCoordinator.go(to: .waitingRoom(roomName))
            } onReturnToLanding: {
                navigationCoordinator.go(to: .landing)
            } additionalContentView: {
                makeGoodbyeAdditionalContentView(roomName: roomName)
            }

            navigationCoordinator.goodByeViewModel = newViewModel
            viewModel = newViewModel
        }

        return goodByePageFactory.make(viewModel: viewModel) {
            makeGoodbyeAdditionalContentView(roomName: roomName)
        }
        .navigationBarHidden(true)
    }

    func makeGoodbyeAdditionalContentView(roomName: RoomName) -> some View {
        #if ARCHIVING_ENABLED
            if let viewModel = navigationCoordinator.archivesViewModel {
                return AnyView(archiveFactory.make(viewModel: viewModel))
            } else {
                let (view, viewModel) = archiveFactory.make(
                    roomName: roomName
                ) { recording in
                    UIApplication.shared.open(recording.url)
                }
                navigationCoordinator.archivesViewModel = viewModel
                return AnyView(view)
            }
        #else
            return EmptyView()
        #endif
    }

    #if CHAT_ENABLED
        private func makeChatView() -> some View {
            let result = chatFactory.make {
                showChat = false
            }
            return result.view
        }
    #endif

    #if REACTIONS_ENABLED
        private func makePickerView() -> some View {
            let view: EmojiPickerViewContainer
            if let viewModel = navigationCoordinator.emojiPickerContainerViewModel {
                view = EmojiPickerViewContainer(viewModel: viewModel)
            } else {
                let result = dependencyContainer.reactionsFactory.makeEmojiPickerContainer()
                navigationCoordinator.emojiPickerContainerViewModel = result.viewModel
                view = result.view
            }

            return view
        }

        @ViewBuilder
        private func makeFloatingEmojisOverlay() -> some View {
            if let viewModel = navigationCoordinator.floatingEmojisOverlayViewModel {
                FloatingEmojisOverlayView(viewModel: viewModel)
            }
        }
    #endif
    
    #if CAPTIONS_ENABLED
        @ViewBuilder
        private func makeCaptionsView() -> some View {
            if let captionsViewModel = navigationCoordinator.captionsViewModel {
                captionsFactory.makeCaptionsView(viewModel: captionsViewModel)
            }
        }
   #endif
}
