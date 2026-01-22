//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation
import VERADomain

public protocol ArchivingStatusDataSource {
    var archivingState: AnyPublisher<ArchivingState, Never> { get }
    func set(archivingState: ArchivingState)
    func reset()
}
