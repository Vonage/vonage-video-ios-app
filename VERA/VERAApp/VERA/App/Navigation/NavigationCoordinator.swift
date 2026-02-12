import Combine
import Foundation
import SwiftUI
import VERACore
import VERADomain
import os.log

#if ARCHIVING_ENABLED
    import VERAArchiving
#endif

#if BACKGROUND_EFFECTS_ENABLED
    import VERABackgroundEffects
#endif

#if REACTIONS_ENABLED
    import VERAReactions
#endif

@MainActor
open class NavigationCoordinator: ObservableObject, Navigator {
    @Published var path = NavigationPath()
    @Published var isInMeeting = false
    @Published var currentMeetingRoom: String?
    @Published var alertItem: AlertItem?

    // Cache for waiting room view models to prevent recreation
    var waitingRoomViewModel: WaitingRoomViewModel?
    var meetingRoomViewModel: MeetingRoomViewModel?
    var goodByeViewModel: GoodByeViewModel?
    #if ARCHIVING_ENABLED
        var archiveButtonViewModel: ArchiveButtonViewModel?
        var archivesViewModel: ArchivesViewModel?
    #endif

    #if BACKGROUND_EFFECTS_ENABLED
        var backgroundBlurButtonViewModel: BackgroundBlurButtonViewModel?
    #endif

    #if REACTIONS_ENABLED
        var emojiPickerComponentViewModel: EmojiPickerContainerViewModel?
    #endif

    func showAlert(_ alert: AlertItem) {
        alertItem = alert
    }

    @MainActor
    public func go(to route: AppRoute) {
        switch route {
        case .landing: returnToLanding()
        case .waitingRoom(let roomName): navigateToWaitingRoom(roomName)
        case .meetingRoom(let roomName): startMeeting(roomName)
        case .goodbye: leaveMeeting()
        case .settings: navigateToSettings()
        }
    }

    // MARK: - Public Navigation Methods

    private func navigateToWaitingRoom(_ roomName: String) {
        isInMeeting = false
        currentMeetingRoom = nil

        path.removeLast(path.count)
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
        // Clear cached view models when returning to landing
        waitingRoomViewModel = nil
        #if ARCHIVING_ENABLED
            archiveButtonViewModel = nil
            archivesViewModel = nil
        #endif

        #if BACKGROUND_EFFECTS_ENABLED
            backgroundBlurButtonViewModel = nil
        #endif

        logNavigation("Returned to landing page")
    }

    private func navigateToSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
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
