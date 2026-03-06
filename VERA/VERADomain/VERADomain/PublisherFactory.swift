//
//  Created by Vonage on 15/7/25.
//

import Foundation

public protocol PublisherFactory {
    func make(_ settings: PublisherSettings) throws -> VERAPublisher
}
