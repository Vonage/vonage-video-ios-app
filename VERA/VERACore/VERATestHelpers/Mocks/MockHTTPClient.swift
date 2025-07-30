//
//  Created by Vonage on 23/7/25.
//

import Foundation
import VERACore

public final class MockHTTPClient: HTTPClient {
    public var data: Data!
    public var recordedURL: URL!

    public init() {}

    public func get(_ url: URL) async throws -> Data {
        self.recordedURL = url
        return self.data
    }
}
