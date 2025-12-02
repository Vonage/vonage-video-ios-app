//
//  Created by Vonage on 16/7/25.
//

import Foundation

public protocol PublisherRepository {
    func getPublisher() throws -> VERAPublisher
    func resetPublisher()
    func recreatePublisher(_ settings: PublisherSettings) throws
}
