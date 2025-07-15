//
//  Created by Vonage on 15/7/25.
//

import Foundation
import SwiftUI

public protocol VERAPublisher {
    var view: AnyView { get }
    var publishAudio: Bool { get set }
    var publishVideo: Bool { get set }
}

public protocol PublisherFactory {
    func make() throws -> VERAPublisher
}
