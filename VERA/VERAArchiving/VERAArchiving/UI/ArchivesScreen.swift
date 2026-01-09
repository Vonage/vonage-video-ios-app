//
//  Created by Vonage on 9/1/26.
//

import SwiftUI
import VERACommonUI

public struct ArchivesScreen: View {

    @ObservedObject var viewModel: ArchivesViewModel

    public var body: some View {
        CardView {
            ArchiveList(archives: viewModel.archives)
                .padding()
        }.padding(.top)
    }
}
