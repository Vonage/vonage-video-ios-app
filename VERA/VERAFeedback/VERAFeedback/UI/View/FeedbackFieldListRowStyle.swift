//
//  Created by Vonage on 10/06/2026.
//

import SwiftUI

private struct FeedbackFieldListRowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
}

extension View {
    func feedbackFieldListRowStyle() -> some View {
        modifier(FeedbackFieldListRowStyle())
    }
}
