//
//  Created by Vonage on 4/7/25.
//

import Foundation
import SwiftUI
import VERACore
import VERAOpenTok

@main
struct VERAApp: App {
    @StateObject var navigationCoordinator = NavigationCoordinator()
    let dependencyContainer = DependencyContainer()

    @State private var previousPath = NavigationPath()
    @State private var alertItem: AlertItem?

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
                        }
                    }
            }
            .fullScreenCover(isPresented: $navigationCoordinator.isInMeeting) {
                if let currentRoom = navigationCoordinator.currentMeetingRoom {
                    makeMeetingRoom(roomName: currentRoom)
                        .onDisappear {
                            dependencyContainer.publisherRepository.resetPublisher()
                        }
                }
            }
            .environmentObject(navigationCoordinator)
            .alert(item: $alertItem) { alertItem in
                Alert(
                    title: Text(alertItem.title),
                    message: Text(alertItem.message),
                    dismissButton: .default(Text("OK"))
                )
            }.onOpenURL { url in
                handleUniversalLink(url)
            }
        }
    }

    private func handleUniversalLink(_ url: URL) {
        guard let roomName = url.getRoomName(from: dependencyContainer.baseURL) else { return }
        navigationCoordinator.navigateToWaitingRoom(roomName)
    }

    // MARK: - Factory Methods

    var landingPageFactory: LandingPageFactory { dependencyContainer.landingPageFactory }
    var waitingRoomFactory: WaitingRoomFactory { dependencyContainer.waitingRoomFactory }
    var meetingRoomFactory: MeetingRoomFactory { dependencyContainer.meetingRoomFactory }
    var goodByePageFactory: GoodByePageFactory { dependencyContainer.goodByePageFactory }

    private func makeLandingPage() -> some View {
        landingPageFactory.make { roomName in
            navigationCoordinator.navigateToWaitingRoom(roomName)
        }
    }

    private func makeWaitingRoom(roomName: String) -> some View {
        waitingRoomFactory.make(
            roomName: roomName
        ) { roomName in
            Task {
                navigationCoordinator.startMeeting(roomName)
            }
        }.onDisappear {
            // Required if the user goes back to the landing page
            dependencyContainer.cameraPreviewProviderRepository.resetPublisher()
        }
    }

    private func makeMeetingRoom(roomName: String) -> some View {
        meetingRoomFactory.make(roomName: roomName) {
            navigationCoordinator.leaveMeeting()
        }
    }

    private func makeGoodbyePage(roomName: String) -> some View {
        goodByePageFactory.make(roomName: roomName) {
            navigationCoordinator.navigateToWaitingRoom(roomName)
        } onReturnToLanding: {
            navigationCoordinator.returnToLanding()
        } onPlay: { _ in

        }
        .navigationBarHidden(true)
    }
}
