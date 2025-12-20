//
//  Created by Vonage on 4/7/25.
//

import Foundation
import SwiftUI
import VERACommonUI
import VERACore
import VERAVonage

#if CHAT_ENABLED
    import VERAChat
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
            .alert(item: $alertItem) { alertItem in
                Alert(
                    title: Text(alertItem.title),
                    message: Text(alertItem.message),
                    dismissButton: .default(Text("OK"))
                )
            }
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

        if let existingViewModel = navigationCoordinator.meetingRoomViewModel,
            existingViewModel.roomName == roomName
        {
            viewModel = existingViewModel
        } else {
            let (_, newViewModel) = meetingRoomFactory.make(roomName: roomName) {
                showChatIfneeded()
            } onBack: {
                navigationCoordinator.go(to: .goodbye(roomName))
            }
            navigationCoordinator.meetingRoomViewModel = newViewModel
            viewModel = newViewModel
        }

        return meetingRoomFactory.make(viewModel: viewModel)
            .onDisappear {
                // Clear view model when leaving the meeting room
                navigationCoordinator.meetingRoomViewModel = nil
            }
    }

    private func showChatIfneeded() {
        #if CHAT_ENABLED
            showChat = true
        #endif
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
            } onPlay: { _ in
            }

            navigationCoordinator.goodByeViewModel = newViewModel
            viewModel = newViewModel
        }

        return goodByePageFactory.make(viewModel: viewModel)
            .navigationBarHidden(true)
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
