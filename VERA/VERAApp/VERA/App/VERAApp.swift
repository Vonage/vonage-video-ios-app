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
                        case let .waitingRoom(roomName):
                            makeWaitingRoom(roomName: roomName)
                        case let .goodbye(roomName):
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
                        .environmentObject(navigationCoordinator)
                }
            }
            .onChange(of: navigationCoordinator.path) { newPath in
                if newPath.count < previousPath.count {
                    print("Publisher is reset when returning to the landing page")
                    dependencyContainer.publisherRepository.resetPublisher()
                }
                previousPath = newPath
            }
            .environmentObject(navigationCoordinator)
            .alert(item: $alertItem) { alertItem in
                Alert(
                    title: Text(alertItem.title),
                    message: Text(alertItem.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
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
        }
    }

    private func makeMeetingRoom(roomName: String) -> some View {
        meetingRoomFactory.make(roomName: roomName) {
            navigationCoordinator.leaveMeeting()
        }
    }

    private func makeGoodbyePage(roomName: String) -> some View {
        goodByePageFactory.make(roomName: roomName) {
            navigationCoordinator.startMeeting(roomName)
        } onReturnToLanding: {
            navigationCoordinator.returnToLanding()
        }
        .navigationBarHidden(true)
    }
}
