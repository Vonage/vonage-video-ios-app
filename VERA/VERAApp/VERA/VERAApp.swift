//
//  Created by Vonage on 4/7/25.
//

import SwiftUI
import VERACore

@main
struct VERAApp: App {
    @State private var isSessionActive = false

    private let navigationCoordinator = NavigationCoordinator()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: navigationCoordinator.path) {
                LandingPageFactory()
                    .make { roomName in
                        navigationCoordinator.navigate(to: AppRoute.waitingRoom(roomName))
                    }
                    .fullScreenCover(isPresented: $isSessionActive) {

                    }
                    .navigationDestination(for: AppRoute.self) { destination in
                        switch destination {
                        case .landing: fatalError("Cant happen")
                        case let .waitingRoom(roomName):
                            WaitingRoomFactory().make { roomName in
                                navigationCoordinator.navigate(to: AppRoute.meetingRoom(roomName))
                            }
                        case .meetingRoom: MeetingRoomView()
                        case .goodbye: GoodByeView()
                        }
                    }
            }
        }
    }
}
