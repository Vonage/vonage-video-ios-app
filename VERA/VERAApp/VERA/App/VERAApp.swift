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
    @State private var alertItem: AlertItem?
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
                        }
                        #if CHAT_ENABLED
                            .sheet(isPresented: $showChat) {
                                makeChatView()
                            }
                        #endif
                }
            }
            .environmentObject(navigationCoordinator)
            .alert(item: $alertItem) { $0.view }
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

    private func makeMeetingRoom(roomName: String) -> some View {
        let viewModel: MeetingRoomViewModel

        var extraButtons: [BottomBarButton] = []

        #if CHAT_ENABLED
            extraButtons.append(mapToChatBottomBarButton())
        #endif

        if let existingViewModel = navigationCoordinator.meetingRoomViewModel,
            existingViewModel.roomName == roomName
        {
            viewModel = existingViewModel
            if let archiveButtonViewModel = navigationCoordinator.archiveButtonViewModel {
                extraButtons.append(mapToArchiveBottomBarButton(archiveButtonViewModel))
            }
        } else {
            let (_, archiveButtonViewModel) = archiveFactory.makeArchivingButton(roomName: roomName)
            extraButtons.append(mapToArchiveBottomBarButton(archiveButtonViewModel))


            let (_, newViewModel) = meetingRoomFactory.make(
                roomName: roomName, extraButtons: extraButtons
            ) {
                navigationCoordinator.go(to: .waitingRoom(roomName))
            } onNext: {
                navigationCoordinator.go(to: .goodbye(roomName))
            }

            navigationCoordinator.meetingRoomViewModel = newViewModel
            navigationCoordinator.archiveButtonViewModel = archiveButtonViewModel
            viewModel = newViewModel
        }

        return meetingRoomFactory.make(viewModel: viewModel, extraButtons: extraButtons)
            .onDisappear {
                // Clear view model when leaving the meeting room
                navigationCoordinator.meetingRoomViewModel = nil
            }
    }

    private func mapToArchiveBottomBarButton(
        _ archiveButtonViewModel: ArchiveButtonViewModel
    ) -> BottomBarButton {
        let archiveButton = archiveFactory.makeArchivingButton(viewModel: archiveButtonViewModel)
        return .init(
            label: "Archive",
            image: VERACommonUIAsset.Images.radioChecked2Line.swiftUIImage,
            onTap: archiveButtonViewModel.onTap,
            content: {
                archiveButton
            })
    }

    #if CHAT_ENABLED
        private func mapToChatBottomBarButton() -> BottomBarButton {
            return .init(
                label: "Chat",
                image: VERACommonUIAsset.Images.chat2Solid.swiftUIImage,
                onTap: showChatIfNeeded,
                content: {
                    ChatBadgeButton(
                        unreadMessagesCount: 0,
                        onShowChat: showChatIfNeeded)
                })
        }

        private func showChatIfNeeded() {
            showChat = true
        }
    #endif

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
            return archiveFactory.make(roomName: roomName).view
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
