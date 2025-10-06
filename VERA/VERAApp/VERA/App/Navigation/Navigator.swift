//
//  Created by Vonage on 6/10/25.
//

import Foundation

@MainActor
public protocol Navigator {
    func go(to route: AppRoute)
}
