//
//  Created by Vonage on 20/4/26.
//

import SwiftUI
import VERACommonUI
import VERAMeetingRoomSDK

@main
struct VERAMeetingRoomSDKDemoApp: App {
    var body: some Scene {
        WindowGroup {
            DemoRootView()
        }
    }
}

// MARK: - Root Navigation

@MainActor
struct DemoRootView: View {
    @State private var prebuilt: MeetingRoomPrebuilt?

    var body: some View {
        ZStack {
            if let prebuilt {
                prebuilt.view
            } else {
                LandingScreen { roomName, baseURL in
                    buildMeetingRoom(roomName: roomName, baseURL: baseURL)
                }
            }
        }
    }

    // MARK: - Meeting Room Building

    private func buildMeetingRoom(roomName: String, baseURL: URL) {
        var theme = MeetingRoomTheme.vonage
        theme.primary = .blue
        prebuilt = MeetingRoomBuilder(
            baseURL: baseURL,
            roomName: roomName
        )
        .theme(theme)
        .publisherSettings(.init())
        .onAction { action in
            handleAction(action)
        }
        .build()
    }

    private func handleAction(_ action: MeetingRoomSDKAction) {
        switch action {
        case .callDidEnd, .goBack:
            prebuilt = nil
        }
    }
}
