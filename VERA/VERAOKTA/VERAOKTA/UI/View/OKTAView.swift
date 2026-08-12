//
//  Created by Vonage on 12/8/26.
//

import SwiftUI

/// Main view for the OKTA feature.
public struct OKTAView: View {
    @ObservedObject private var viewModel: OKTAViewModel

    public init(viewModel: OKTAViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        // TODO: Implement view
        Text("OKTA")
    }
}
