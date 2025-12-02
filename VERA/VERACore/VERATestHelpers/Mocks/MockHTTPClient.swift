//
//  Created by Vonage on 23/7/25.
//

import Foundation
import VERACore

public final class MockHTTPClient: HTTPClient {
    public var data = Data()
    public var shouldThrowError = false
    public var delaySeconds: TimeInterval = 0
    public var callCount = 0
    public var recordedURL: URL!

    public init(
        data: Data = Data(),
        shouldThrowError: Bool = false,
        delaySeconds: TimeInterval = 0,
        callCount: Int = 0,
        recordedURL: URL! = nil
    ) {
        self.data = data
        self.shouldThrowError = shouldThrowError
        self.delaySeconds = delaySeconds
        self.callCount = callCount
        self.recordedURL = recordedURL
    }

    public func get(_ url: URL) async throws -> Data {
        callCount += 1
        recordedURL = url

        if delaySeconds > 0 {
            try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
        }

        if shouldThrowError {
            throw MockHTTPError()
        }

        return data
    }
}

public struct MockHTTPError: Error, Equatable {}
