//
//  Created by Vonage on 23/4/26.
//

import VERADomain

/// Bridge that delegates alert presentation to an ``AlertPresentable``.
///
/// Injected into the view layer; keeps UI concerns decoupled from
/// view models and factories. Accepts any ``AlertPresentable``
/// implementation, defaulting to ``UIKitAlertPresenter``.
@MainActor
final class AlertPresenter {
    private var presenter: AlertPresentable?

    init() {
        self.presenter = UIKitAlertPresenter()
    }

    init(presenter: AlertPresentable) {
        self.presenter = presenter
    }

    func present(_ alertItem: AlertItem) {
        presenter?.presentAlert(alertItem)
    }

    func reset() {
        presenter = nil
    }
}
