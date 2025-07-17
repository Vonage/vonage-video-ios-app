//
//  Created by Vonage on 16/7/25.
//

import Foundation

public protocol PublisherRepository {
    func getPublisher() -> VERAPublisher
    func resetPublisher()
}
