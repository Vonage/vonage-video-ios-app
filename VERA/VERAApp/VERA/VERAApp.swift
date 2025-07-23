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
                        case .landing: EmptyView()
                        case let .waitingRoom(roomName):
                            makeWaitingRoom(roomName: roomName)
                        case let .meetingRoom(roomName):
                            makeMeetingRoom(roomName: roomName)
                        case .goodbye: EmptyView()
                        }
                    }
            }
            .fullScreenCover(isPresented: $navigationCoordinator.isInMeeting) {
                if let currentRoom = navigationCoordinator.currentMeetingRoom {
                    makeMeetingRoom(roomName: currentRoom)
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
            Task {
                navigationCoordinator.startMeeting(roomName)
            }
        }
    }

    private func makeMeetingRoom(roomName: String) -> some View {
        dependencyContainer.meetingRoomFactory.make(roomName: roomName)
    }
}
