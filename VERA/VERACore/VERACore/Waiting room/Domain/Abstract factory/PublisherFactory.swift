//
//  Created by Vonage on 15/7/25.
//

import Foundation

public protocol PublisherFactory {
    func make() -> VERAPublisher
}
