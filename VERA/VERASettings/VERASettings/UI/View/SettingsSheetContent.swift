//
//  Created by Vonage on 21/05/2026.
//

import SwiftUI

/// Wrapper view that owns the settings view models via `@StateObject`.
///
/// `@StateObject` ensures the view models are created once when the sheet
/// appears and survive any parent re-renders while the sheet is presented.
/// They are automatically destroyed when the sheet is dismissed.
public struct SettingsSheetContent: View {
    @StateObject private var viewModel: SettingsViewModel
    @StateObject private var statisticsViewModel: StatisticsViewModel

    public init(factory: SettingsFactory) {
        let (vm, statsVM) = factory.makeMeetingRoomViewModels()
        _viewModel = StateObject(wrappedValue: vm)
        _statisticsViewModel = StateObject(wrappedValue: statsVM)
    }

    public var body: some View {
        SettingsView(viewModel: viewModel, statisticsViewModel: statisticsViewModel)
    }
}
