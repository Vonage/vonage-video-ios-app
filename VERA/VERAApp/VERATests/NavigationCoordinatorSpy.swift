//
//  Created by Vonage on 6/10/25.
//

import Foundation
import VERADomain

@testable import VERA

@MainActor
class NavigationCoordinatorSpy: Navigator {

    var navigationRoutes: [AppRoute] = []
    var alerts: [AlertItem] = []

    @MainActor
    init() {
    }

    func go(to route: AppRoute) {
        navigationRoutes.append(route)
    }

    func showAlert(_ alert: AlertItem) {
        alerts.append(alert)
    }
}
