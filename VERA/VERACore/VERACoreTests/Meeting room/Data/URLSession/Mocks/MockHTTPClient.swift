//
//  Created by Vonage on 23/7/25.
//

import Foundation
import VERACore

final class MockHTTPClient: HTTPClient {
    var data: Data!
    var recordedURL: URL!

    func get(_ url: URL) async throws -> Data {
        self.recordedURL = url
        return self.data
    }
}
