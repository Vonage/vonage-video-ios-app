//
//  Created by Vonage on 30/7/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

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
            Text("Download session content", bundle: .veraArchiving)
                .adaptiveFont(.heading1)
                .foregroundStyle(theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, ArchiveListConstants.titleBottomPadding)

            if archives.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        VERACommonUIAsset.Images.videoActiveLine.swiftUIImage
                        Text("This session has no content to download", bundle: .veraArchiving)
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
                            archive.kind.listIcon
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
                            switch archive.downloadState {
                            case .ready:
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
                                    .accessibilityIdentifier(archive.kind.downloadButtonAccessibilityID)
                                }
                            case .preparing:
                                ProgressView()
                                    .frame(
                                        width: ArchiveListConstants.progressViewSize,
                                        height: ArchiveListConstants.progressViewSize
                                    )
                            case .unavailable:
                                VERACommonUIAsset.Images.errorLine.swiftUIImage
                                    .foregroundStyle(theme.error)
                                    .frame(
                                        width: ArchiveListConstants.progressViewSize,
                                        height: ArchiveListConstants.progressViewSize
                                    )
                                    .accessibilityLabel(
                                        Text("This file failed or is expired", bundle: .veraArchiving))
                            }
                        }
                    }
                    .accessibilityIdentifier(archive.kind.listItemAccessibilityID)
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
            kind: .transcription,
            title: "Your transcription is being prepared",
            subtitle: "Please wait while we prepare your downloads",
            downloadState: .preparing),
        .init(
            id: .init(),
            title: "Recording 2",
            subtitle: "0:30 • 1.0 MB • Created: Mon, Aug 4 12:09 PM",
            downloadState: .ready),
        .init(
            id: .init(),
            kind: .transcription,
            title: "Transcription 1",
            subtitle: "0:30 • 120.0 KB • Created: Mon, Aug 4 12:09 PM",
            downloadState: .ready),
        .init(
            id: .init(),
            title: "Recording 1",
            subtitle: "0:30 • 1.0 MB • Created: Mon, Aug 4 12:09 PM",
            downloadState: .unavailable),
    ])
}
