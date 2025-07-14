//
//  Created by Vonage on 8/7/25.
//

import SwiftUI
import os.log

@MainActor
final class NavigationCoordinator: ObservableObject {
    @Published var route: AppRoute = .landing

    func navigate(to path: String) {
        if let route = AppRoute(path: path) {
            self.route = route
        } else {
            // Log invalid route attempts for debugging
            #if DEBUG
                os_log("Invalid route: %@", log: OSLog.default, type: .debug, path)
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
