//
//  Created by Vonage on 10/06/2026.
//



struct FeedbackInfoFieldView: View {

    @ObservedObject var feedbackFieldViewModel: FeedbackFieldViewModel

    var body: some View {
        Text(feedbackFieldViewModel.value)
            .font(.body)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .feedbackFieldListRowStyle()
    }
}