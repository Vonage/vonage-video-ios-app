//
//  Created by Vonage on 15/7/25.
//

import Foundation

@MainActor
public protocol PublisherFactory: Sendable {
    func make(_ settings: PublisherSettings) throws -> VERAPublisher
}
