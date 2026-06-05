//
//  Created by Vonage on 21/04/2026.
//

import SwiftUI
import VERASettings

// MARK: - Settings Overlay Modifier

struct SettingsOverlayModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var showSettings: Bool
    let statsOverlayViewModel: StatsOverlayViewModel?
    let container: MeetingRoomSDKContainer

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .sheet(isPresented: $showSettings) {
                    SettingsSheetContent(factory: container.settingsFactory)
                        .presentationDetents([.large])
                }
                .overlay {
                    if let statsViewModel = statsOverlayViewModel {
                        container.settingsFactory.makeStatsOverlayView(viewModel: statsViewModel)
                    }
                }
        } else {
            content
        }
    }
}


struct FeedbackFormOverlayModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var showFeedbackForm: Bool
    let statsOverlayViewModel: StatsOverlayViewModel?
    let container: MeetingRoomSDKContainer

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .sheet(isPresented: $showFeedbackForm) {
                    Text("feedback form")
                }
                .overlay {
                    if let statsViewModel = statsOverlayViewModel {
                        container.settingsFactory.makeStatsOverlayView(viewModel: statsViewModel)
                    }
                }
        } else {
            content
        }
    }
}
