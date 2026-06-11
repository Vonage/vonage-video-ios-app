/// Wrapper view that owns the feedback view model via `@StateObject`.
///
/// `@StateObject` ensures the view model is created once when the sheet
/// appears and survives any parent re-renders while the sheet is presented.
public struct FeedbackSheetContent: View {
    @StateObject private var feedbackSectionViewModel = FeedbackSectionViewModel()
    
    
    public init() {
    }

    public var body: some View {
        FeedbackView(feedbackSectionViewModel: feedbackSectionViewModel)
    }
}