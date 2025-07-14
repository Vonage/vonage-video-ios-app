//
//  Created by Vonage on 4/7/25.
//

import Foundation
import SwiftUI
import VERACore

@main
struct VERAApp: App {
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    private let landingPageFactory = LandingPageFactory()
    private let waitingRoomFactory = WaitingRoomFactory()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationCoordinator.path) {
                landingPageFactory
                    .make { roomName in
                        navigationCoordinator.navigateToWaitingRoom(roomName)
                    }
                    .navigationDestination(for: AppRoute.self) { destination in
                        switch destination {
                        case .landing: EmptyView()
                        case let .waitingRoom(roomName):
                            waitingRoomFactory
                                .make(roomName: roomName) { roomName in
                                    navigationCoordinator.startMeeting(roomName)
                                }
                                .navigationBarBackButtonHidden(false)
                                .navigationBarTitleDisplayMode(.inline)
                        case .meetingRoom(_): EmptyView()
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
}
