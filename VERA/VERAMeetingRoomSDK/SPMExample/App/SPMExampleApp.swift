//
//  Created by Vonage on 22/4/26.
//

import SwiftUI
import VERADomain
import VERAMeetingRoomSDK

@main
struct SPMExampleApp: App {
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
    @State private var activeAlert: AlertItem?

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
        .alert(item: $activeAlert) { item in
            if let cancelAction = item.cancelAction {
                return Alert(
                    title: Text(item.title),
                    message: Text(item.message),
                    primaryButton: .default(Text(item.okAction ?? String(localized: "OK")), action: item.onConfirm),
                    secondaryButton: .cancel(Text(cancelAction))
                )
            } else {
                return Alert(
                    title: Text(item.title),
                    message: Text(item.message),
                    dismissButton: .default(Text(item.okAction ?? String(localized: "OK")), action: item.onConfirm)
                )
            }
        }
    }

    // MARK: - Meeting Room Building

    private func buildMeetingRoom(roomName: String, baseURL: URL) {
        prebuilt = MeetingRoomBuilder(
            baseURL: baseURL,
            roomName: roomName
        )
        .enabledFeatures([.chat, .captions, .reactions, .settings])
        .onAction { action in
            handleAction(action)
        }
        .build()
    }

    private func handleAction(_ action: MeetingRoomSDKAction) {
        switch action {
        case .callDidEnd, .goBack:
            prebuilt = nil
        case .presentAlert(let alertItem):
            activeAlert = alertItem
        }
    }
}
