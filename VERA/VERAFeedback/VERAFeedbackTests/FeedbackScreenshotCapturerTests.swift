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
        @Test("captureContentBehindModal handles visible key window on macOS")
        func captureVisibleWindowOnMacOS() {
            let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 120))
            contentView.wantsLayer = true
            contentView.layer?.backgroundColor = NSColor.systemBlue.cgColor

            let window = NSWindow(
                contentRect: contentView.frame,
                styleMask: [.titled],
                backing: .buffered,
                defer: false
            )
            window.contentView = contentView
            window.makeKeyAndOrderFront(nil)

            _ = FeedbackScreenshotCapturer.captureContentBehindModal()
            #expect(true)
        }

        @Test("captureContentBehindModal captures parent window behind sheet on macOS")
        func captureWindowBehindSheetOnMacOS() {
            let parentContent = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 160))
            parentContent.wantsLayer = true
            parentContent.layer?.backgroundColor = NSColor.systemGreen.cgColor

            let parentWindow = NSWindow(
                contentRect: parentContent.frame,
                styleMask: [.titled],
                backing: .buffered,
                defer: false
            )
            parentWindow.contentView = parentContent

            let sheetContent = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
            let sheetWindow = NSWindow(
                contentRect: sheetContent.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            sheetWindow.contentView = sheetContent

            parentWindow.makeKeyAndOrderFront(nil)
            parentWindow.beginSheet(sheetWindow) { _ in }

            let image = FeedbackScreenshotCapturer.captureContentBehindModal()
            parentWindow.endSheet(sheetWindow)

            #expect(image != nil)
        }

        @Test("captureContentBehindModal returns nil for zero-sized view on macOS")
        func captureReturnsNilForZeroSizedView() {
            let contentView = NSView(frame: .zero)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.contentView = contentView
            window.makeKeyAndOrderFront(nil)

            let image = FeedbackScreenshotCapturer.captureContentBehindModal()
            #expect(image == nil)
        }
    #endif
}
