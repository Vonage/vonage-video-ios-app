//
//  Created by Vonage on 9/1/26.
//

import SwiftUI
import VERACommonUI

public struct ArchivesScreen: View {

    @Bindable var viewModel: ArchivesViewModel

    public var body: some View {
        CardView {
            ArchiveList(archives: viewModel.archives, downloadingArchiveIDs: viewModel.downloadingArchiveIDs)
        }
        .sheet(item: $viewModel.sharedTranscript) { transcript in
            ShareSheet(fileURL: transcript.fileURL)
        }
        .alert(item: $viewModel.error) { $0.view }
    }
}
