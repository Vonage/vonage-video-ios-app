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
            // Log invalid route attempts for debugging
            #if DEBUG
                print("Invalid route: \(path)")  // swiftlint:disable:this no_print
            #endif
        }
    }

    func navigate(to route: AppRoute) {
        self.route = route
    }

    func reset() {
        self.route = .landing
    }
}
