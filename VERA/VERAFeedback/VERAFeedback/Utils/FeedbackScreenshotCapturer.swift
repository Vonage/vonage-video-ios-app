//
//  Created by Vonage on 11/06/2026.
//

import UIKit

enum FeedbackScreenshotCapturer {

    @MainActor
    static func captureContentBehindModal() -> UIImage? {
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
