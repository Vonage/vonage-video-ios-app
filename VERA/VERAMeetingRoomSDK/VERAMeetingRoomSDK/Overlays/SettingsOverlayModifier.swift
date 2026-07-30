//
//  Created by Vonage on 21/04/2026.
//

import SwiftUI
import UIKit
import VERASettings

// MARK: - Settings Overlay Modifier

struct SettingsOverlayModifier: ViewModifier {
    @Environment(\.meetingRoomTheme) private var theme

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
                        .opaquePresentationBackground(theme.background)
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
