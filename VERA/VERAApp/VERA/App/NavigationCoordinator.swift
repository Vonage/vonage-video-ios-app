import Foundation
import SwiftUI
import os.log

@MainActor
final class NavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    @Published var isInMeeting = false
    @Published var currentMeetingRoom: String?

    // MARK: - Public Navigation Methods

    func navigateToWaitingRoom(_ roomName: String) {
        path.append(AppRoute.waitingRoom(roomName))
        logNavigation("Navigating to waiting room: \(roomName)")
    }

    func startMeeting(_ roomName: String) {
        currentMeetingRoom = roomName
        isInMeeting = true
        logNavigation("Starting meeting: \(roomName)")
    }

    func leaveMeeting() {
        isInMeeting = false
        currentMeetingRoom = nil

        path.append(AppRoute.goodbye)
        logNavigation("Left meeting, navigating to goodbye")
    }

    func returnToLanding() {
        path.removeLast(path.count)  // Limpia todo el stack
        isInMeeting = false
        currentMeetingRoom = nil
        logNavigation("Returned to landing page")
    }

    func goBack() {
        if !path.isEmpty {
            path.removeLast()
            logNavigation("Navigated back")
        }
    }

    // MARK: - Private Helpers

    private func logNavigation(_ message: String) {
        #if DEBUG
            os_log("%@", log: OSLog.default, type: .debug, "🧭 Navigation: \(message)")
            print("🧭 Navigation: \(message)")
        #endif
    }
}

// MARK: - App Routes
enum AppRoute: Hashable {
    case landing
    case waitingRoom(String)
    case meetingRoom(String)
    case goodbye

    var description: String {
        switch self {
        case .landing:
            return "Landing"
        case .waitingRoom(let room):
            return "WaitingRoom(\(room))"
        case .meetingRoom(let room):
            return "MeetingRoom(\(room))"
        case .goodbye:
            return "Goodbye"
        }
    }
}
