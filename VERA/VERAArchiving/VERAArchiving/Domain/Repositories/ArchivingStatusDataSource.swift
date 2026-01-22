//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation

public protocol ArchivingStatusDataSource {
    var archivingStatus: AnyPublisher<Bool, Never> { get }
    func set(archivingStatus: Bool)
    func reset()
}
