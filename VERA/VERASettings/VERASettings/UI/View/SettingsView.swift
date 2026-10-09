//
//  Created by Vonage on 25/2/26.
//

import SwiftUI
import VERACommonUI

/// Adaptive settings dashboard.
///
/// - **Regular width**: `NavigationSplitView` with a sidebar list and a detail pane.
/// - **Compact width**: A single scrollable `Form` containing every section inline.
///
/// Both layouts use the same section order.
///
/// Sections are defined in ``SettingsSection``.
public struct SettingsView: View {

    /// Context used to decide whether the settings are editable during an active call.
    public enum CallContext {
        case waitingRoom
        case activeCall

        var isInActiveCall: Bool {
            self == .activeCall
        }
    }

    /// Environment action to dismiss the current presentation.
    @Environment(\.dismiss) private var dismiss

    /// Current horizontal size class for determining layout adaptations.
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    /// View model managing settings state and user actions.
    @Bindable var viewModel: SettingsViewModel

    /// View model for real-time statistics (placeholder when not in a meeting).
    private var statisticsViewModel: StatisticsViewModel

    /// Whether the screen is being shown while a call is already active.
    private let callContext: CallContext

    /// Currently selected section in the sidebar (iPad/Mac only).
    @State private var selectedSection: SettingsSection?

    /// Whether this view has a real statistics view model (vs. placeholder).
    /// Used to conditionally show live stats in the meeting room.
    private var hasStatisticsViewModel: Bool {
        statisticsViewModel !== StatisticsViewModel.placeholder
    }

    private var currentStatisticsViewModel: StatisticsViewModel? {
        hasStatisticsViewModel ? statisticsViewModel : nil
    }

    /// Creates a settings view without real-time stats (waiting room).
    ///
    /// - Parameters:
    ///   - viewModel: The settings view model managing state and actions.
    ///   - selectedSection: The initially selected section for iPad/Mac sidebar. Defaults to `.general`.
    public init(
        viewModel: SettingsViewModel,
        selectedSection: SettingsSection = .general,
        callContext: CallContext = .waitingRoom
    ) {
        self.viewModel = viewModel
        self.statisticsViewModel = StatisticsViewModel.placeholder
        self.callContext = callContext
        self._selectedSection = State(initialValue: selectedSection)
    }

    /// Creates a settings view with real-time stats (meeting room).
    ///
    /// - Parameters:
    ///   - viewModel: The settings view model managing state and actions.
    ///   - statisticsViewModel: View model providing live network statistics during an active call.
    ///   - selectedSection: The initially selected section for iPad/Mac sidebar. Defaults to `.general`.
    public init(
        viewModel: SettingsViewModel,
        statisticsViewModel: StatisticsViewModel,
        selectedSection: SettingsSection = .general,
        callContext: CallContext = .activeCall
    ) {
        self.viewModel = viewModel
        self.statisticsViewModel = statisticsViewModel
        self.callContext = callContext
        self._selectedSection = State(initialValue: selectedSection)
    }

    public var body: some View {
        Group {
            if horizontalSizeClass?.isRegularLayout == true {
                regularLayout
            } else {
                compactLayout
            }
        }
        .task {
            await viewModel.setup()
        }
    }

    // MARK: - Compact (iPhone)

    /// Single scrollable form with all sections inline.
    ///
    /// Used on iPhone and iPad in compact width (e.g., slideover, split view).
    /// Displays all settings sections in a single form with no navigation hierarchy.
    /// Changes are auto-saved; a Close button dismisses the sheet.
    private var compactLayout: some View {
        NavigationStack {
            Form {
                ForEach(SettingsSection.allCases) { section in
                    compactSection(for: section)
                }
            }
            .navigationTitle("Settings".localized)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close".localized) {
                        Task { @MainActor in
                            await viewModel.dismiss()
                            dismiss()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .accessibilityIdentifier(SettingsAccessibilityID.screen)
    }

    // MARK: - Regular (iPad / Mac)

    /// Sidebar + detail split view.
    ///
    /// Used on iPad in regular width and on Mac.
    /// Displays a sidebar with section navigation and a detail pane showing the selected section's content.
    /// Uses `.balanced` style to give equal priority to sidebar and detail.
    private var regularLayout: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView(for: selectedSection ?? .general)
        }
        .navigationSplitViewStyle(.balanced)
        .accessibilityIdentifier(SettingsAccessibilityID.screen)
    }

    // MARK: - Sidebar

    /// Sidebar list showing all available settings sections.
    ///
    /// Displays section icons and names. Selected section drives the detail pane content.
    /// Changes are auto-saved; a Close button dismisses the sheet.
    private var sidebar: some View {
        List(SettingsSection.allCases, selection: $selectedSection) { section in
            Label(section.displayName, systemImage: section.iconName)
        }
        .navigationTitle("Settings".localized)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "Close")) {
                    Task { @MainActor in
                        await viewModel.dismiss()
                        dismiss()
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Detail

    /// Creates the detail view for the given settings section.
    ///
    /// - Parameter section: The section to display.
    /// - Returns: A form containing the appropriate section view.
    ///
    /// The view is identified by section to force SwiftUI to recreate it on selection changes,
    /// ensuring proper state management.
    @ViewBuilder
    private func detailView(for section: SettingsSection) -> some View {
        Form {
            sectionContent(for: section, isCompactLayout: false)
        }
        .scrollContentBackground(.hidden)
        .id(section)
        .navigationTitle(section.displayName)
    }

    @ViewBuilder
    private func compactSection(for section: SettingsSection) -> some View {
        if section == .stats {
            sectionContent(for: section, isCompactLayout: true)
        } else {
            Section {
                sectionContent(for: section, isCompactLayout: true)
            } header: {
                Text(section.displayName)
                    .foregroundStyle(VERACommonUIAsset.SemanticColors.textPrimary.swiftUIColor)
            }
        }
    }

    @ViewBuilder
    private func sectionContent(for section: SettingsSection, isCompactLayout: Bool) -> some View {
        switch section {
        case .general:
            GeneralSectionView(
                viewModel: viewModel,
                isInActiveCall: callContext.isInActiveCall,
                statsOverlayEnabled: $viewModel.settingsPreference.statsOverlayEnabled,
                isCompactLayout: isCompactLayout
            )
        case .video:
            VideoSectionView(
                viewModel: viewModel,
                isInActiveCall: callContext.isInActiveCall,
                isCompactLayout: isCompactLayout
            )
        case .screenSharing:
            ScreenSharingSectionView(viewModel: viewModel, isCompactLayout: isCompactLayout)
        case .audio:
            AudioSectionView(
                viewModel: viewModel,
                isInActiveCall: callContext.isInActiveCall,
                isCompactLayout: isCompactLayout
            )
        case .stats:
            StatisticsSectionScreen(
                viewModel: viewModel,
                statisticsViewModel: currentStatisticsViewModel,
                isCompactLayout: isCompactLayout,
                showsSectionHeaders: isCompactLayout
            )
        }
    }

}

// MARK: - Previews

#if DEBUG
    #Preview("iPhone - Waiting Room") {
        SettingsView(viewModel: .preview)
            .preferredColorScheme(.dark)
    }

    #Preview("iPhone - Meeting Room") {
        SettingsView(
            viewModel: .preview,
            statisticsViewModel: .placeholder,
            callContext: .activeCall
        )
        .preferredColorScheme(.dark)
    }

    #Preview("iPad - Waiting Room") {
        SettingsView(viewModel: .preview)
            .environment(\.horizontalSizeClass, .regular)
            .preferredColorScheme(.dark)
    }

    #Preview("iPad - Meeting Room") {
        SettingsView(
            viewModel: .preview,
            statisticsViewModel: .placeholder,
            callContext: .activeCall
        )
        .environment(\.horizontalSizeClass, .regular)
        .preferredColorScheme(.dark)
    }
#endif
