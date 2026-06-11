private struct FeedbackFieldListRowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
}

extension View {
    fileprivate func feedbackFieldListRowStyle() -> some View {
        modifier(FeedbackFieldListRowStyle())
    }
}