//
//  Created by Vonage on 30/7/25.
//

import SwiftUI
import VERACommonUI

/// Layout constants for the archive list view.
private enum ArchiveListConstants {
    /// Bottom padding below the section title.
    static let titleBottomPadding: CGFloat = 10
    /// Top padding above the divider in the empty state.
    static let dividerTopPadding: CGFloat = 8
    /// Size of the progress spinner in the download column.
    static let progressViewSize: CGFloat = 44
    /// Top inset for each list row.
    static let rowInsetTop: CGFloat = 4
    /// Leading inset for each list row.
    static let rowInsetLeading: CGFloat = 8
    /// Bottom inset for each list row.
    static let rowInsetBottom: CGFloat = 4
    /// Trailing inset for each list row.
    static let rowInsetTrailing: CGFloat = 8
}

struct ArchiveList: View {

    @Environment(\.meetingRoomTheme) private var theme

    let archives: [ArchiveUIData]

    init(archives: [ArchiveUIData] = []) {
        self.archives = archives
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Download recording", bundle: .veraArchiving)
                .adaptiveFont(.heading1)
                .foregroundStyle(theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, ArchiveListConstants.titleBottomPadding)

            if archives.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        VERACommonUIAsset.Images.videoActiveLine.swiftUIImage
                        Text("The meeting hasn't been recorded", bundle: .veraArchiving)
                            .adaptiveFont(.bodyBase)
                            .foregroundStyle(theme.textSecondary)
                    }
                    Divider()
                        .foregroundColor(theme.border)
                        .padding(.top, ArchiveListConstants.dividerTopPadding)
                }
            } else {
                List(archives, id: \.id) { archive in
                    HStack {
                        VStack(alignment: .center) {
                            VERACommonUIAsset.Images.videoActiveLine.swiftUIImage
                        }
                        VStack(alignment: .leading) {
                            Text(archive.title)
                                .adaptiveFont(.bodyBase)
                                .foregroundStyle(theme.textSecondary)
                            Text(archive.subtitle)
                                .adaptiveFont(.bodyBase)
                                .foregroundStyle(theme.textTertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .center) {
                            if archive.isDownloadable {
                                Button {
                                    archive.onDownload?()
                                } label: {
                                    HStack(alignment: .center) {
                                        VERACommonUIAsset.Images.downloadLine.swiftUIImage
                                            .foregroundStyle(theme.primary)
                                        Text("Download", bundle: .veraArchiving)
                                            .adaptiveFont(.bodyBase)
                                            .foregroundStyle(theme.primary)
                                    }
                                }
                                .accessibilityIdentifier(ArchivingAccessibilityID.downloadButton)
                            } else {
                                ProgressView()
                                    .frame(
                                        width: ArchiveListConstants.progressViewSize,
                                        height: ArchiveListConstants.progressViewSize
                                    )
                            }
                        }
                    }
                    .accessibilityIdentifier(ArchivingAccessibilityID.archiveItem)
                    .listRowInsets(
                        EdgeInsets(
                            top: ArchiveListConstants.rowInsetTop,
                            leading: ArchiveListConstants.rowInsetLeading,
                            bottom: ArchiveListConstants.rowInsetBottom,
                            trailing: ArchiveListConstants.rowInsetTrailing
                        )
                    )
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .accessibilityIdentifier(ArchivingAccessibilityID.archiveList)
    }
}

#Preview {
    ArchiveList()
}

#Preview {
    ArchiveList(archives: [
        .init(
            id: .init(),
            title: "Recording 1",
            subtitle: "Started at: Mon, Aug 4 12:09 PM",
            isDownloadable: true),
        .init(
            id: .init(),
            title: "Recording 2",
            subtitle: "Started at: Mon, Aug 4 12:09 PM",
            isDownloadable: true),
        .init(
            id: .init(),
            title: "Recording 3",
            subtitle: "Started at: Mon, Aug 4 12:09 PM",
            isDownloadable: false),
    ])
}
