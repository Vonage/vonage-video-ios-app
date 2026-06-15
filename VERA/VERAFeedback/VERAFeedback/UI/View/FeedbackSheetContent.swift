//
//  Created by Vonage on 10/06/2026.
//

import SwiftUI

public struct FeedbackSheetContent: View {
    @StateObject private var feedbackFormViewModel = FeedbackFormViewModel()

    public init() {}

    public var body: some View {
        FeedbackView(feedbackFormViewModel: feedbackFormViewModel)
    }
}
