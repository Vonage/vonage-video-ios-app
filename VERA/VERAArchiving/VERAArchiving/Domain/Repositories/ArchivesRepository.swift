//
//  Created by Vonage on 4/8/25.
//

import Combine
import Foundation
import VERADomain

public protocol ArchivesRepository {
    func getArchives(sessionKey: String) async -> AnyPublisher<[Archive], Error>
}
