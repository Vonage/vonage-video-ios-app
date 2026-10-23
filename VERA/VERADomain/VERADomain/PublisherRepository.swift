//
//  Created by Vonage on 16/7/25.
//

import Foundation

@MainActor
public protocol PublisherRepository: Sendable {
    func getPublisher() throws -> VERAPublisher
    func resetPublisher()
    func recreatePublisher(_ settings: PublisherSettings) throws
}
