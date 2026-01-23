//
//  Created by Vonage on 23/7/25.
//

import Foundation

public protocol HTTPClient {
    func get(_ url: URL) async throws -> Data
    func post(_ url: URL, data: Data) async throws -> Data
}
