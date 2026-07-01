import SwiftUI
import UIKit

@testable import VERAFeedback

@MainActor
enum FeedbackSnapshotInteractionHelpers {

    @MainActor
    struct HostedContext {
        let window: UIWindow
        let rootView: UIView

        func textInputs() -> [UIView] {
            findViews(in: rootView) { view in
                view is UITextField || view is UITextView
            }
        }

        func focusTextInput(at index: Int) -> Bool {
            let inputs = textInputs()
            guard inputs.indices.contains(index) else { return false }
            inputs[index].becomeFirstResponder()
            settle()
            return inputs[index].isFirstResponder
        }

        func tapAllKeyboardToolbarButtons() {
            guard let accessory = inputAccessoryView() else { return }
            let controls = findViews(in: accessory) { $0 is UIControl }
            for control in controls {
                guard let uiControl = control as? UIControl else { continue }
                controlSendAction(control: uiControl)
            }
            settle()
        }

        func tapKeyboardToolbarButton(labeled label: String) -> Bool {
            guard let accessory = inputAccessoryView() else { return false }
            guard
                let button = findViews(
                    in: accessory,
                    where: { view in
                        guard let control = view as? UIControl else { return false }
                        let accessibilityLabel = control.accessibilityLabel ?? ""
                        return accessibilityLabel.localizedCaseInsensitiveContains(label)
                    }
                ).first as? UIControl
            else {
                return false
            }
            controlSendAction(control: button)
            settle()
            return true
        }

        func tapKeyboardToolbarButtonsMatching(_ predicate: (String) -> Bool) -> Bool {
            guard let accessory = inputAccessoryView() else { return false }
            let controls = findViews(in: accessory) { $0 is UIControl }
            for control in controls {
                guard let uiControl = control as? UIControl else { continue }
                let label = uiControl.accessibilityLabel ?? ""
                if predicate(label) {
                    controlSendAction(control: uiControl)
                    settle()
                    return true
                }
            }
            return false
        }

        func tapButton(labeled label: String) -> Bool {
            guard
                let button = findViews(
                    in: rootView,
                    where: { view in
                        guard let control = view as? UIControl else { return false }
                        let accessibilityLabel = control.accessibilityLabel ?? ""
                        return accessibilityLabel.localizedCaseInsensitiveContains(label)
                    }
                ).first as? UIControl
            else {
                return false
            }
            controlSendAction(control: button)
            settle()
            return true
        }

        func tapSendButton() -> Bool {
            if tapAccessibilityIdentifier("send_button") { return true }
            if tapButton(labeled: String(localized: "Send")) { return true }
            return tapFirstButton()
        }

        func tapAccessibilityIdentifier(_ identifier: String) -> Bool {
            guard
                let view = findViews(in: rootView, where: { $0.accessibilityIdentifier == identifier }).first
            else {
                return false
            }
            guard let control = view as? UIControl else { return false }
            controlSendAction(control: control)
            settle()
            return true
        }

        func tapFirstButton() -> Bool {
            guard let control = findViews(in: rootView, where: { $0 is UIButton }).first as? UIButton else {
                return false
            }
            controlSendAction(control: control)
            settle()
            return true
        }

        private func inputAccessoryView() -> UIView? {
            if let accessory = textInputs().first(where: { $0.isFirstResponder })?.inputAccessoryView {
                return accessory
            }
            return findViews(in: rootView) { view in
                String(describing: type(of: view)).localizedCaseInsensitiveContains("InputAccessory")
                    || String(describing: type(of: view)).localizedCaseInsensitiveContains("Toolbar")
            }.first
        }

        private func controlSendAction(control: UIControl) {
            if let button = control as? UIButton {
                button.sendActions(for: .touchUpInside)
                return
            }
            control.sendActions(for: .primaryActionTriggered)
        }

        private func findViews(
            in root: UIView,
            where predicate: (UIView) -> Bool
        ) -> [UIView] {
            var matches: [UIView] = []
            if predicate(root) {
                matches.append(root)
            }
            for subview in root.subviews {
                matches.append(contentsOf: findViews(in: subview, where: predicate))
            }
            return matches
        }
    }

    static func host<V: View>(
        _ view: V,
        size: CGSize = CGSize(width: 390, height: 900)
    ) -> HostedContext {
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(origin: .zero, size: size)

        let window: UIWindow
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            window = UIWindow(windowScene: scene)
            window.frame = CGRect(origin: .zero, size: size)
        } else {
            window = UIWindow(frame: CGRect(origin: .zero, size: size))
        }

        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        settle()
        return HostedContext(window: window, rootView: hostingController.view)
    }

    static func settle() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.15))
    }
}
