//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation

public protocol ArchivingStatusDataSource {
    func archivingStatus() -> AnyPublisher<Bool, Never>
    func set(archivingStatus: Bool)
    func reset()
}
