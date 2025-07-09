//
//  Created by Vonage on 8/7/25.
//

import SwiftUI

@MainActor
final class NavigationCoordinator: ObservableObject {
    @Published var route: AppRoute = .landing

    func navigate(to path: String) {
        if let route = AppRoute(path: path) {
            self.route = route
        } else {
            print("Invalid route: \(path)")
        }
    }

    func navigate(to route: AppRoute) {
        self.route = route
    }

    func reset() {
        self.route = .landing
    }
}
