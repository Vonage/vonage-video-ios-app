//
//  Created by Vonage on 6/10/25.
//

import Foundation
import VERADomain

@MainActor
public protocol Navigator {
    func go(to route: AppRoute)
    func showAlert(_ alert: AlertItem)
}
