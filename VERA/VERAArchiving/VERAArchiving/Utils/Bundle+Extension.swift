//
//  Created by Vonage on 8/1/26.
//

import Foundation

final class VERAArchiving {}

extension Bundle {
    static var veraArchiving: Bundle {
        Bundle(for: VERAArchiving.self)
    }
}
