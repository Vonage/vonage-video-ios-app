//
//  Created by Vonage on 4/7/25.
//

import Foundation
import SwiftUI
import VERACore
import VERAOpenTok

@main
struct VERAApp: App {
    @StateObject private var navigationCoordinator = NavigationCoordinator()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationCoordinator.path) {
                makeLandingPage()
                    .navigationDestination(for: AppRoute.self) { destination in
                        switch destination {
                        case .landing: EmptyView()
                        case let .waitingRoom(roomName): makeWaitingRoom(roomName: roomName)
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
        let publisherFactory: PublisherFactory = OpenTokPublisherFactory()
        let waitingRoomFactory = WaitingRoomFactory(publisherFactory: publisherFactory)

        return waitingRoomFactory.make(roomName: roomName) { roomName in
            navigationCoordinator.startMeeting(roomName)
        }
    }

    private func makeMeetingRoom() -> some View {
        MeetingRoomView()
    }
}
