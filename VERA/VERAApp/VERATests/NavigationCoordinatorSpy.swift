//
//  Created by Vonage on 6/10/25.
//

import Foundation

@testable import VERA

@MainActor
class NavigationCoordinatorSpy: Navigator {

    var navigationRoutes: [AppRoute] = []

    @MainActor
    init() {
    }

    func go(to route: AppRoute) {
        navigationRoutes.append(route)
    }
}
