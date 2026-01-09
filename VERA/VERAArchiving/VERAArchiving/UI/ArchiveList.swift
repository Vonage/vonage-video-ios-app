//
//  Created by Vonage on 30/7/25.
//

import SwiftUI
import VERACommonUI

struct ArchiveList: View {

    let archives: [ArchiveUIData]

    init(archives: [ArchiveUIData] = []) {
        self.archives = archives
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Download recording", bundle: .veraArchiving)
                .adaptiveFont(.heading1)
                .foregroundStyle(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)

            if archives.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        VERACommonUIAsset.Images.videoActiveLine.swiftUIImage
                        Text("The meeting hasn't been recorded", bundle: .veraArchiving)
                            .adaptiveFont(.bodyBase)
                            .foregroundStyle(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
                    }
                    Divider()
                        .foregroundColor(VERACommonUIAsset.SemanticColors.border.swiftUIColor)
                        .padding(.top, 8)
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
                                .foregroundStyle(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
                            Text(archive.subtitle)
                                .adaptiveFont(.bodyBase)
                                .foregroundStyle(VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .center) {
                            if archive.isDownloadable {
                                Button {
                                    archive.onDownload?()
                                } label: {
                                    HStack(alignment: .center) {
                                        VERACommonUIAsset.Images.downloadLine.swiftUIImage
                                            .foregroundStyle(VERACommonUIAsset.SemanticColors.primary.swiftUIColor)
                                        Text("Download")
                                            .adaptiveFont(.bodyBase)
                                            .foregroundStyle(VERACommonUIAsset.SemanticColors.primary.swiftUIColor)
                                    }
                                }
                            } else {
                                ProgressView()
                                    .frame(width: 44, height: 44)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
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
