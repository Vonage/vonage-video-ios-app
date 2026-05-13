//
//  Created by Vonage on 12/05/2026.
//

import UIKit
import VERADomain

/// Concrete UIKit implementation of ``AlertPresentable``.
///
/// Finds the topmost view controller and presents a `UIAlertController`.
/// Bypasses SwiftUI `.alert` issues when triggered from overflow `Menu` buttons.
@MainActor
public final class UIKitAlertPresenter: AlertPresentable {

    // No stored properties — public init required for external instantiation.
    public init() {}

    public func presentAlert(_ alertItem: AlertItem) {
        guard
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let alert = UIAlertController(
            title: alertItem.title,
            message: alertItem.message,
            preferredStyle: .alert
        )

        let confirmTitle = alertItem.okAction ?? String(localized: "OK")
        alert.addAction(
            UIAlertAction(title: confirmTitle, style: .default) { _ in
                alertItem.onConfirm?()
            }
        )

        if let cancelTitle = alertItem.cancelAction {
            alert.addAction(
                UIAlertAction(title: cancelTitle, style: .cancel)
            )
        }

        topVC.present(alert, animated: true)
    }
}
