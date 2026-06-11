//
//  Created by Vonage on 11/06/2026.
//

import Foundation

enum FeedbackScreenshotCapturer {

    /// Captures the content behind the currently presented modal and returns it as a platform image.
    ///
    /// - Returns: A snapshot of the screen behind the modal, or `nil` when no modal is presented.
    @MainActor
    static func captureContentBehindModal() -> PlatformImage? {
        #if canImport(UIKit)
        return captureOnUIKit()
        #elseif canImport(AppKit)
        return captureOnAppKit()
        #else
        return nil
        #endif
    }
}

#if canImport(UIKit)
import UIKit

extension FeedbackScreenshotCapturer {
    @MainActor
    private static func captureOnUIKit() -> UIImage? {
        guard let presenter = presenterOfTopmostModal() else {
            return nil
        }
        return render(presenter.view)
    }

    @MainActor
    private static func presenterOfTopmostModal() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        let activeScene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        guard let scene = activeScene else { return nil }

        let windows = scene.windows.filter { !$0.isHidden && $0.alpha > 0 }
        let hostWindow = windows.first { $0.isKeyWindow } ?? windows.first
        guard let root = hostWindow?.rootViewController else { return nil }

        var presenter: UIViewController?
        var current: UIViewController = root
        while let presented = current.presentedViewController {
            presenter = current
            current = presented
        }
        return presenter
    }

    @MainActor
    private static func render(_ view: UIView) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = view.window?.screen.scale ?? UIScreen.main.scale
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(bounds: view.bounds, format: format)
        return renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
        }
    }
}

#elseif canImport(AppKit)
import AppKit

extension FeedbackScreenshotCapturer {
    @MainActor
    private static func captureOnAppKit() -> NSImage? {
        guard let window = windowBehindModal(),
            let contentView = window.contentView
        else {
            return nil
        }
        return render(contentView)
    }

    @MainActor
    private static func windowBehindModal() -> NSWindow? {
        let visibleWindows = NSApplication.shared.windows.filter(\.isVisible)

        if let sheetWindow = visibleWindows.first(where: { $0.isKeyWindow && $0.sheetParent != nil }) {
            return sheetWindow.sheetParent
        }

        if let parentWindow = visibleWindows.first(where: { $0.attachedSheet != nil }) {
            return parentWindow
        }

        if let keyWindow = NSApplication.shared.keyWindow, keyWindow.sheetParent == nil {
            return keyWindow
        }

        return NSApplication.shared.mainWindow
    }

    @MainActor
    private static func render(_ view: NSView) -> NSImage? {
        guard view.bounds.width > 0, view.bounds.height > 0 else { return nil }

        guard let bitmapRep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
            return nil
        }

        view.cacheDisplay(in: view.bounds, to: bitmapRep)

        let image = NSImage(size: view.bounds.size)
        image.addRepresentation(bitmapRep)
        return image
    }
}
#endif
