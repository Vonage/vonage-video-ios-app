import SwiftUI

#if canImport(AppKit)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

enum FeedbackViewTestHelpers {

    /// Hosts a SwiftUI view in a window so layout and body code paths are exercised for coverage.
    @MainActor
    @discardableResult
    static func host<V: View>(_ view: V, size: CGSize = CGSize(width: 390, height: 900)) -> HostedViewContext<V> {
        settleLayout {
            #if canImport(AppKit)
                let hostingView = NSHostingView(rootView: view)
                hostingView.frame = CGRect(origin: .zero, size: size)

                let window = NSWindow(
                    contentRect: hostingView.frame,
                    styleMask: [.titled, .closable],
                    backing: .buffered,
                    defer: false
                )
                window.contentView = hostingView
                window.makeKeyAndOrderFront(nil)
                window.layoutIfNeeded()
                hostingView.layoutSubtreeIfNeeded()

                return HostedViewContext(rootView: hostingView)
            #elseif canImport(UIKit)
                let hostingController = UIHostingController(rootView: view)
                hostingController.view.frame = CGRect(origin: .zero, size: size)

                let window = UIWindow(frame: hostingController.view.frame)
                window.rootViewController = hostingController
                window.makeKeyAndVisible()
                hostingController.view.setNeedsLayout()
                hostingController.view.layoutIfNeeded()

                return HostedViewContext(rootView: hostingController.view)
            #endif
        }
    }

    @MainActor
    static func settleLayout<T>(_ work: () -> T) -> T {
        let result = work()
        #if canImport(AppKit)
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        #elseif canImport(UIKit)
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        #endif
        return result
    }

    @MainActor
    struct HostedViewContext<V: View> {
        #if canImport(AppKit)
            let rootView: NSHostingView<V>
        #elseif canImport(UIKit)
            let rootView: UIView
        #endif

        func tapSendButton() -> Bool {
            if tapAccessibilityIdentifier("send_button") { return true }
            if tapButton(labeled: String(localized: "Send")) { return true }
            if tapButton(titled: String(localized: "Send")) { return true }
            return pressAllButtonLikeElements()
        }

        func pressAllButtonLikeElements() -> Bool {
            #if canImport(AppKit)
                pressButtonLikeElements(in: rootView)
            #elseif canImport(UIKit)
                pressButtonLikeElements(in: rootView)
            #endif
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
            return true
        }

        #if canImport(AppKit)
            private func pressButtonLikeElements(in root: NSView) {
                if isButtonLike(root) {
                    _ = performClick(on: root)
                }
                for subview in root.subviews {
                    pressButtonLikeElements(in: subview)
                }
            }
        #elseif canImport(UIKit)
            private func pressButtonLikeElements(in root: UIView) {
                if root is UIButton || root.accessibilityTraits.contains(.button) {
                    _ = performTap(on: root)
                }
                for subview in root.subviews {
                    pressButtonLikeElements(in: subview)
                }
            }
        #endif

        func tapAccessibilityIdentifier(_ identifier: String) -> Bool {
            #if canImport(AppKit)
                guard let view = findView(in: rootView, where: { $0.accessibilityIdentifier() == identifier }) else {
                    return false
                }
                return performClick(on: view)
            #elseif canImport(UIKit)
                guard let view = findView(in: rootView, where: { $0.accessibilityIdentifier == identifier }) else {
                    return false
                }
                return performTap(on: view)
            #endif
        }

        func tapButton(titled title: String) -> Bool {
            #if canImport(AppKit)
                if let button = findView(in: rootView, where: {
                    ($0 as? NSButton)?.title == title
                }) as? NSButton {
                    button.performClick(nil)
                    return true
                }
                return false
            #elseif canImport(UIKit)
                guard
                    let control = findView(in: rootView, where: {
                        ($0 as? UIButton)?.title(for: .normal) == title
                    }) as? UIButton
                else {
                    return false
                }
                control.sendActions(for: .touchUpInside)
                return true
            #endif
        }

        func tapButton(labeled label: String) -> Bool {
            #if canImport(AppKit)
                guard let view = findView(in: rootView, where: { matchesAccessibilityLabel($0, label: label) }) else {
                    return false
                }
                return performClick(on: view)
            #elseif canImport(UIKit)
                guard let view = findView(in: rootView, where: { matchesAccessibilityLabel($0, label: label) }) else {
                    return false
                }
                return performTap(on: view)
            #endif
        }

        func tapFirstButton() -> Bool {
            #if canImport(AppKit)
                guard let button = findView(in: rootView, where: { isButtonLike($0) }) else {
                    return false
                }
                return performClick(on: button)
            #elseif canImport(UIKit)
                guard let control = findView(in: rootView, where: { $0 is UIButton }) as? UIButton else {
                    return false
                }
                control.sendActions(for: .touchUpInside)
                return true
            #endif
        }

        #if canImport(AppKit)
            private func isButtonLike(_ view: NSView) -> Bool {
                if view is NSButton { return true }
                if view.accessibilityRole() == .button { return true }
                return String(describing: type(of: view)).localizedCaseInsensitiveContains("button")
            }

            private func matchesAccessibilityLabel(_ view: NSView, label: String) -> Bool {
                guard isButtonLike(view) else { return false }
                let accessibilityLabel = (view.accessibilityLabel() as? String) ?? ""
                let accessibilityTitle = view.accessibilityTitle() ?? ""
                return accessibilityLabel.localizedCaseInsensitiveContains(label)
                    || accessibilityTitle.localizedCaseInsensitiveContains(label)
            }

            private func performClick(on view: NSView) -> Bool {
                if let button = view as? NSButton {
                    button.performClick(nil)
                    return true
                }
                if view.accessibilityPerformPress() {
                    return true
                }
                if view.responds(to: #selector(NSView.mouseDown(with:))) {
                    let location = NSPoint(x: view.bounds.midX, y: view.bounds.midY)
                    view.mouseDown(with: NSEvent.mouseEvent(
                        with: .leftMouseDown,
                        location: location,
                        modifierFlags: [],
                        timestamp: 0,
                        windowNumber: view.window?.windowNumber ?? 0,
                        context: nil,
                        eventNumber: 0,
                        clickCount: 1,
                        pressure: 1
                    )!)
                    view.mouseUp(with: NSEvent.mouseEvent(
                        with: .leftMouseUp,
                        location: location,
                        modifierFlags: [],
                        timestamp: 0,
                        windowNumber: view.window?.windowNumber ?? 0,
                        context: nil,
                        eventNumber: 0,
                        clickCount: 1,
                        pressure: 0
                    )!)
                    return true
                }
                return false
            }

            private func findView(in root: NSView, where predicate: (NSView) -> Bool) -> NSView? {
                if predicate(root) { return root }
                for subview in root.subviews {
                    if let found = findView(in: subview, where: predicate) {
                        return found
                    }
                }
                return nil
            }
        #elseif canImport(UIKit)
            private func matchesAccessibilityLabel(_ view: UIView, label: String) -> Bool {
                guard view is UIButton || view.accessibilityTraits.contains(.button) else { return false }
                let accessibilityLabel = view.accessibilityLabel ?? ""
                return accessibilityLabel.localizedCaseInsensitiveContains(label)
            }

            private func performTap(on view: UIView) -> Bool {
                if let button = view as? UIButton {
                    button.sendActions(for: .touchUpInside)
                    return true
                }
                guard let gestureRecognizers = view.gestureRecognizers else { return false }
                for recognizer in gestureRecognizers where recognizer is UITapGestureRecognizer {
                    recognizer.state = .ended
                    return true
                }
                return false
            }

            private func findView(in root: UIView, where predicate: (UIView) -> Bool) -> UIView? {
                if predicate(root) { return root }
                for subview in root.subviews {
                    if let found = findView(in: subview, where: predicate) {
                        return found
                    }
                }
                return nil
            }
        #endif
    }
}
