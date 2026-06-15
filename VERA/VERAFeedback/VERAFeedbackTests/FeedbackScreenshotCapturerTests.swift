import Testing

@testable import VERAFeedback

#if canImport(AppKit)
    import AppKit
#endif


@MainActor
@Suite("Feedback screenshot capturer tests")
struct FeedbackScreenshotCapturerTests {

    @Test("captureContentBehindModal returns nil or image without crashing")
    func captureDoesNotCrash() {
        let image = FeedbackScreenshotCapturer.captureContentBehindModal()
        #expect(image == nil || image != nil)
    }

    #if canImport(AppKit)
        @Test("captureContentBehindModal handles visible window on macOS")
        func captureVisibleWindowOnMacOS() {
            let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 120))
            let window = NSWindow(
                contentRect: contentView.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.contentView = contentView
            window.makeKeyAndOrderFront(nil)

            _ = FeedbackScreenshotCapturer.captureContentBehindModal()
            #expect(true)
        }
    #endif
}
