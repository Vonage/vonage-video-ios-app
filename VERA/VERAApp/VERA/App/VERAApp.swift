//
//  Created by Vonage on 4/7/25.
//

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
                        .alert(item: $navigationCoordinator.alertItem) { $0.view }
                        #if CHAT_ENABLED
                            .sheet(isPresented: $showChat) {
                                makeChatView()
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

    private func makeLandingPage() -> some View {
        landingPageFactory.make { roomName in
            navigationCoordinator.go(to: .waitingRoom(roomName))
        }
    }

    private func makeWaitingRoom(roomName: String) -> some View {
        let viewModel: WaitingRoomViewModel

        if let existingViewModel = navigationCoordinator.waitingRoomViewModel,
            existingViewModel.roomName == roomName
        {
            // Reuse existing view model for the same room
            viewModel = existingViewModel
        } else {
            // Create new view model for different room
            let (_, newViewModel) = waitingRoomFactory.make(
                roomName: roomName
            ) { roomName in
                Task {
                    navigationCoordinator.go(to: .meetingRoom(roomName))
                }
            }
            newViewModel.extraTrailingButtons = makeWaitingRoomTrailingButtons()
            viewModel = newViewModel
            navigationCoordinator.waitingRoomViewModel = newViewModel
        }

        return waitingRoomFactory.make(viewModel: viewModel)
            .onDisappear {
                // Required if the user goes back to the landing page
                dependencyContainer.cameraPreviewProviderRepository.resetPublisher()
                // Clear view model when leaving the waiting room
                navigationCoordinator.waitingRoomViewModel = nil
            }
    }

    private func makeWaitingRoomTrailingButtons() -> [ViewHolder] {
        var result = [ViewHolder]()

        #if BACKGROUND_EFFECTS_ENABLED

            result.append(
                .init(
                    id: "Blur",
                    content: {
                        backgroundBlurFactory.makeBlurButton().view
                    }))

        #endif

        return result
    }

    private func makeMeetingRoom(roomName: String) -> some View {
        let viewModel: MeetingRoomViewModel

        if let existingViewModel = navigationCoordinator.meetingRoomViewModel,
            existingViewModel.roomName == roomName
        {
            viewModel = existingViewModel
        } else {
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
                getExternalButtons: getBottomBarButtons
            ) {
                navigationCoordinator.go(to: .waitingRoom(roomName))
            } onNext: {
                navigationCoordinator.go(to: .goodbye(roomName))
            }

            navigationCoordinator.meetingRoomViewModel = newViewModel
            #if ARCHIVING_ENABLED
                navigationCoordinator.archiveButtonViewModel = archiveButtonViewModel
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
                dependencyContainer.mapToChatBottomBarButton(onShowChat: {
                    showChat = true
                }))
        #endif

        #if BACKGROUND_EFFECTS_ENABLED

            if let backgroundBlurButtonViewModel = navigationCoordinator.backgroundBlurButtonViewModel {
                extraButtons.append(
                    .init(
                        label: "Blur",
                        image: VERACommonUIAsset.Images.blurLine.swiftUIImage,
                        onTap: {
                            backgroundBlurButtonViewModel.onTap()
                        },
                        content: {
                            backgroundBlurFactory.makeBlurButton(viewModel: backgroundBlurButtonViewModel)
                        })
                )
            } else {
                let (view, viewModel) = backgroundBlurFactory.makeBlurButton()
                navigationCoordinator.backgroundBlurButtonViewModel = viewModel

                extraButtons.append(
                    .init(
                        label: "Blur",
                        image: VERACommonUIAsset.Images.blurLine.swiftUIImage,
                        onTap: {
                            viewModel.onTap()
                        },
                        content: {
                            view
                        })
                )
            }

        #endif

        #if ARCHIVING_ENABLED
            if let archiveButtonViewModel = navigationCoordinator.archiveButtonViewModel {
                extraButtons.append(dependencyContainer.mapToArchiveBottomBarButton(archiveButtonViewModel, state))
            }
        #endif
        return extraButtons
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
}
