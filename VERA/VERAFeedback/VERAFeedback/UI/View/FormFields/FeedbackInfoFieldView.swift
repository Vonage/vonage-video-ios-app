//
//  Created by Vonage on 10/06/2026.
//

import SwiftUI
import VERACommonUI

struct FeedbackInfoFieldView: View {

    var feedbackFieldViewModel: FeedbackFieldViewModel

    var body: some View {
        Text(feedbackFieldViewModel.value.localized(bundle: .module))
            .font(.body)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .feedbackFieldListRowStyle()
    }
}
