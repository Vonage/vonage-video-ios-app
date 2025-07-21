//
//  Created by Vonage on 17/7/25.
//

import Foundation

public protocol HTTPClient {
    func get(_ url: URL) async throws -> Data
}
