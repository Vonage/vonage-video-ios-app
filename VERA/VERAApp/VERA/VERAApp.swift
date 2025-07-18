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

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationCoordinator.path) {
                makeLandingPage()
                    .navigationDestination(for: AppRoute.self) { destination in
                        switch destination {
                        case .landing: EmptyView()
                        case let .waitingRoom(roomName):
                            makeWaitingRoom(roomName: roomName)
                        case .meetingRoom: makeMeetingRoom()
                        case .goodbye: EmptyView()
                        }
                    }
            }
            .fullScreenCover(isPresented: $navigationCoordinator.isInMeeting) {
                if let currentRoom = navigationCoordinator.currentMeetingRoom {
                    MeetingRoomView()
                        .onDisappear {
                            navigationCoordinator.leaveMeeting()
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
        }
    }

    // MARK: - Factory Methods

    private func makeLandingPage() -> some View {
        let factory = LandingPageFactory()
        return factory.make { roomName in
            navigationCoordinator.navigateToWaitingRoom(roomName)
        }
    }

    private func makeWaitingRoom(roomName: String) -> some View {
        dependencyContainer.waitingRoomFactory.make(
            roomName: roomName
        ) { roomName in
            navigationCoordinator.startMeeting(roomName)
        }
    }

    private func makeMeetingRoom() -> some View {
        MeetingRoomView()
    }
}
