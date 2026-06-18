import Testing

@testable import VERAFeedback

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif


@MainActor
enum FeedbackTestHelpers {

    static func makeFormViewModel(
        feedbackReportUseCase: FeedbackReportUseCase? = nil,
        sessionDebugInfoProvider: @escaping () -> FeedbackSessionDebugInfo = { .empty }
    ) -> FeedbackFormViewModel {
        FeedbackFormViewModel(
            feedbackReportUseCase: feedbackReportUseCase
                ?? DefaultFeedbackReportUseCase(
                    feedbackReportDataSource: MockFeedbackReportDataSource()
                ),
            sessionDebugInfoProvider: sessionDebugInfoProvider
        )
    }

    static func fillRequiredTextFields(in viewModel: FeedbackFormViewModel) {
        viewModel.feedbackFields[0].value = "Joining a video call with three participants"
        viewModel.feedbackFields[1].value = "Alex Johnson"
        viewModel.feedbackFields[2].value =
            "The video froze for several seconds whenever someone shared their screen."
    }

    #if canImport(UIKit)
        static func makeTestImage(size: CGSize = CGSize(width: 200, height: 120)) -> UIImage {
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                UIColor.systemBlue.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
        }
    #elseif canImport(AppKit)
        static func makeTestImage(size: NSSize = NSSize(width: 200, height: 120)) -> NSImage {
            let image = NSImage(size: size)
            image.lockFocus()
            NSColor.systemBlue.setFill()
            NSRect(origin: .zero, size: size).fill()
            image.unlockFocus()
            return image
        }
    #endif
}
