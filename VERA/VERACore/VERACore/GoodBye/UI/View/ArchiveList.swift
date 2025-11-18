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
        VStack(alignment: .leading) {
            Text("Recordings", bundle: .veraCore)
                .adaptiveFont(.heading4)
                .foregroundStyle(VERACommonUIAsset.SemanticColors.textPrimary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
            if archives.isEmpty {
                Text("There are no recordings for this meeting", bundle: .veraCore)
                    .adaptiveFont(.subtitle)
                    .foregroundStyle(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
            } else {
                ForEach(archives, id: \.id) { archive in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(archive.title)
                                .font(.title2)
                            Text(archive.subtitle)
                                .foregroundStyle(VERACommonUIAsset.Colors.uiSecondaryLabel.swiftUIColor)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .center) {
                            if archive.isDownloadable {
                                Button {
                                    archive.onDownload?()
                                } label: {
                                    Image(systemName: "square.and.arrow.down")
                                        .foregroundStyle(VERACommonUIAsset.Colors.uiSecondaryLabel.swiftUIColor)
                                }.frame(width: 44, height: 44)
                            } else {
                                ProgressView()
                                    .frame(width: 44, height: 44)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }.padding(.horizontal, 8)
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
