//
//  Created by Vonage on 25/2/26.
//

import SwiftUI

/// Adaptive settings dashboard.
///
/// - **iPad / Mac** (`pad` or `mac` idiom): `NavigationSplitView` with a sidebar
///   list and a detail pane showing the selected section.
/// - **iPhone** (`phone` idiom): A single scrollable `Form` containing
///   every section inline — no drill-down navigation required.
///
/// Device idiom is used instead of `horizontalSizeClass` because iPad sheets
/// report `.compact` size class, which would incorrectly trigger the iPhone layout.
///
/// Sections are defined in ``SettingsSection``.
public struct SettingsView: View {
    
    /// Environment action to dismiss the current presentation.
    @Environment(\.dismiss) private var dismiss
    
    /// Current horizontal size class for determining layout adaptations.
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    /// View model managing settings state and user actions.
    @ObservedObject var viewModel: SettingsViewModel
    
    /// View model for real-time statistics (placeholder when not in a meeting).
    @ObservedObject private var statisticsViewModel: StatisticsViewModel
    
    /// Currently selected section in the sidebar (iPad/Mac only).
    @State private var selectedSection: SettingsSection?

    /// Whether this view has a real statistics view model (vs. placeholder).
    /// Used to conditionally show live stats in the meeting room.
    private var hasStatisticsViewModel: Bool {
        statisticsViewModel !== StatisticsViewModel .placeholder
    }

    /// Creates a settings view without real-time stats (waiting room).
    ///
    /// - Parameters:
    ///   - viewModel: The settings view model managing state and actions.
    ///   - selectedSection: The initially selected section for iPad/Mac sidebar. Defaults to `.general`.
    public init(viewModel: SettingsViewModel, selectedSection: SettingsSection = .general) {
        self.viewModel = viewModel
        self.statisticsViewModel = StatisticsViewModel.placeholder
        self._selectedSection = State(initialValue: selectedSection)
    }

    /// Creates a settings view with real-time stats (meeting room).
    ///
    /// - Parameters:
    ///   - viewModel: The settings view model managing state and actions.
    ///   - statisticsViewModel: View model providing live network statistics during an active call.
    ///   - selectedSection: The initially selected section for iPad/Mac sidebar. Defaults to `.general`.
    public init(viewModel: SettingsViewModel, statisticsViewModel: StatisticsViewModel, selectedSection: SettingsSection = .general) {
        self.viewModel = viewModel
        self.statisticsViewModel = statisticsViewModel
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
    /// Includes Cancel and Save buttons in the toolbar.
    private var compactLayout: some View {
        NavigationStack {
            Form {
                VideoSectionView(viewModel: viewModel)
                AudioSectionView(viewModel: viewModel)
                StatisticsSectionView(
                    viewModel: viewModel,
                    statisticsViewModel: hasStatisticsViewModel ? statisticsViewModel : nil
                )
                GeneralSectionView(viewModel: viewModel)
            }
            .navigationTitle("Settings".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) {
                        viewModel.save()
                        dismiss()
                    }
                }
            }
        }
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
    }

    // MARK: - Sidebar

    /// Sidebar list showing all available settings sections.
    ///
    /// Displays section icons and names. Selected section drives the detail pane content.
    /// Includes Cancel and Save buttons in the toolbar.
    private var sidebar: some View {
        List(SettingsSection.allCases, selection: $selectedSection) { section in
            Label(section.displayName, systemImage: section.iconName)
        }
        .navigationTitle("Settings".localized)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "Cancel")) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "Save")) {
                    viewModel.save()
                    dismiss()
                }
            }
        }
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
            switch section {
            case .general:
                GeneralSectionView(viewModel: viewModel)
            case .video:
                VideoSectionView(viewModel: viewModel)
            case .audio:
                AudioSectionView(viewModel: viewModel)
            case .stats:
                StatisticsSectionView(
                    viewModel: viewModel,
                    statisticsViewModel: hasStatisticsViewModel ? statisticsViewModel : nil
                )
            }
        }
        .id(section)
        .navigationTitle(section.displayName)
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
        statisticsViewModel: .placeholder
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
        statisticsViewModel: .placeholder
    )
    .environment(\.horizontalSizeClass, .regular)
    .preferredColorScheme(.dark)
}
#endif
