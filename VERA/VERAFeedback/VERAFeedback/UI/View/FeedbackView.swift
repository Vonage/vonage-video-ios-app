//
//  Created by Vonage on 3/6/26.
//

import SwiftUI

/// Main view for the Feedback feature.
public struct FeedbackView: View {
    @ObservedObject private var viewModel: FeedbackViewModel

    public init(viewModel: FeedbackViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        // TODO: Implement view
        Text("Feedback")
    }
}
