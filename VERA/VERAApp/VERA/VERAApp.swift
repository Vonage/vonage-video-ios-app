//
//  Created by Vonage on 4/7/25.
//

import SwiftUI
import VERACore

@main
struct VERAApp: App {
    @State private var isSessionActive = false
    @State private var path = NavigationPath()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $path) {
                LandingPageFactory()
                    .make { roomName in
                        path.append(AppRoute.waitingRoom(roomName))
                    }
                    .fullScreenCover(isPresented: $isSessionActive) {

                    }
                    .navigationDestination(for: AppRoute.self) { destination in
                        switch destination {
                        case .landing: fatalError("Cant happen")
                        case let .waitingRoom(roomName): WaitingRoomView(roomName: roomName)
                        case .meetingRoom: MeetingRoomView()
                        case .goodbye: GoodByeView()
                        }
                    }
            }
        }
    }
}
