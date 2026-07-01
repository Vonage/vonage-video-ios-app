import Combine
import Foundation
import SwiftUI
import VERACore
import VERADomain
import VERAMeetingRoom
import VERAMeetingRoomSDK
import os.log

#if ARCHIVING_ENABLED
    import VERAArchiving
#endif

#if BACKGROUND_EFFECTS_ENABLED
    import VERABackgroundEffects
#endif

#if SETTINGS_ENABLED
    import VERASettings
#endif

#if AUDIOEFFECTS_ENABLED
    import VERAAudioEffects
#endif

@MainActor
open class NavigationCoordinator: ObservableObject, Navigator {
    @Published var path = NavigationPath()
    @Published var isInMeeting = false
    @Published var currentMeetingRoomRequest: NewRoomRequest?
    @Published var alertItem: AlertItem?

    // Cache for waiting room view models to prevent recreation
    var waitingRoomViewModel: WaitingRoomViewModel?
    var meetingRoomViewModel: MeetingRoomViewModel?
    var meetingRoomPrebuilt: MeetingRoomPrebuilt?
    var goodByeViewModel: GoodByeViewModel?

    #if ARCHIVING_ENABLED
        var archivesViewModel: ArchivesViewModel?
    #endif

    #if BACKGROUND_EFFECTS_ENABLED
        var videoEffectsViewModel: VideoEffectsViewModel?
    #endif

    #if AUDIOEFFECTS_ENABLED
        var waitingNoiseSuppressionViewModel: WaitingNoiseSuppressionViewModel?
    #endif

    func showAlert(_ alert: AlertItem) {
        alertItem = alert
    }

    @MainActor
    public func go(to route: AppRoute) {
        switch route {
        case .landing: returnToLanding()
        case .waitingRoom(let roomName): navigateToWaitingRoom(roomName)
        case .meetingRoom(let request): startMeeting(request)
        case .goodbye: leaveMeeting()
        case .settings: navigateToSettings()
        }
    }

    // MARK: - Public Navigation Methods

    private func navigateToWaitingRoom(_ roomName: String) {
        isInMeeting = false
        currentMeetingRoomRequest = nil

        path.removeLast(path.count)
        path.append(AppRoute.waitingRoom(roomName))
        logNavigation("Navigating to waiting room: \(roomName)")
    }

    private func startMeeting(_ request: NewRoomRequest) {
        currentMeetingRoomRequest = request
        isInMeeting = true

        path.removeLast(path.count)
        path.append(AppRoute.goodbye(request.roomName))
        logNavigation("Starting meeting: \(request.roomName)")
    }

    private func leaveMeeting() {
        isInMeeting = false
        currentMeetingRoomRequest = nil

        logNavigation("Left meeting, navigating to goodbye")
    }

    private func returnToLanding() {
        path.removeLast(path.count)
        isInMeeting = false
        currentMeetingRoomRequest = nil
        // Clear cached view models when returning to landing
        waitingRoomViewModel = nil

        #if ARCHIVING_ENABLED
            archivesViewModel = nil
        #endif

        #if BACKGROUND_EFFECTS_ENABLED
            videoEffectsViewModel = nil
        #endif

        #if AUDIOEFFECTS_ENABLED
            waitingNoiseSuppressionViewModel = nil
        #endif

        logNavigation("Returned to landing page")
    }

    // MARK: - Private Helpers

    private func navigateToSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func logNavigation(_ message: String) {
        #if DEBUG
            os_log("%@", log: OSLog.default, type: .debug, "🧭 Navigation: \(message)")
            print("🧭 Navigation: \(message)")
        #endif
    }
}
