//
//  Created by Vonage on 5/8/25.
//

import Foundation

public protocol ArchivesDataSource: Sendable {
    func getArchives(sessionKey: String) async throws -> [Archive]
}
