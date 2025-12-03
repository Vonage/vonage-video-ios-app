import Combine
import Foundation
import SwiftUI
import os.log

@MainActor
open class NavigationCoordinator: ObservableObject, Navigator {
    @Published var path = NavigationPath()
    @Published var isInMeeting = false
    @Published var currentMeetingRoom: String?

    public func go(to route: AppRoute) {
        switch route {
        case .landing: returnToLanding()
        case .waitingRoom(let roomName): navigateToWaitingRoom(roomName)
        case .meetingRoom(let roomName): startMeeting(roomName)
        case .goodbye: leaveMeeting()
        }
    }

    // MARK: - Public Navigation Methods

    private func navigateToWaitingRoom(_ roomName: String) {
        path.append(AppRoute.waitingRoom(roomName))
        logNavigation("Navigating to waiting room: \(roomName)")
    }

    private func startMeeting(_ roomName: String) {
        currentMeetingRoom = roomName
        isInMeeting = true

        path.removeLast(path.count)
        path.append(AppRoute.goodbye(roomName))
        logNavigation("Starting meeting: \(roomName)")
    }

    private func leaveMeeting() {
        isInMeeting = false
        currentMeetingRoom = nil

        logNavigation("Left meeting, navigating to goodbye")
    }

    private func returnToLanding() {
        path.removeLast(path.count)
        isInMeeting = false
        currentMeetingRoom = nil
        logNavigation("Returned to landing page")
    }

    // MARK: - Private Helpers

    private func logNavigation(_ message: String) {
        #if DEBUG
            os_log("%@", log: OSLog.default, type: .debug, "🧭 Navigation: \(message)")
            print("🧭 Navigation: \(message)")
        #endif
    }
}
