struct FeedbackFormOverlayModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var showFeedbackForm: Bool
    let statsOverlayViewModel: StatsOverlayViewModel?
    let container: MeetingRoomSDKContainer

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .sheet(isPresented: $showFeedbackForm) {
                    FeedbackSheetContent()
                        .presentationDetents([.large])
                }
        } else {
            content
        }
    }
}
