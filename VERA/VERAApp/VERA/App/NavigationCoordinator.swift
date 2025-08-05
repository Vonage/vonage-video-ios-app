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
        
        // Ensure we navigate away from the waiting room before starting the meeting.
        // Having two views referencing the same publisher or subscriber video view
        // can cause video loss or rendering issues, especially when rotating the device.
        path.removeLast(path.count)
        logNavigation("Starting meeting: \(roomName)")
    }

    func leaveMeeting() {
        isInMeeting = false
        let lastRoomName = currentMeetingRoom ?? ""
        currentMeetingRoom = nil

        path.append(AppRoute.goodbye(lastRoomName))
        logNavigation("Left meeting, navigating to goodbye")
    }

    func returnToLanding() {
        path.removeLast(path.count)
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
    case waitingRoom(String)
    case goodbye(String)

    var description: String {
        switch self {
        case .waitingRoom(let room):
            return "WaitingRoom(\(room))"
        case .goodbye:
            return "Goodbye"
        }
    }
}
