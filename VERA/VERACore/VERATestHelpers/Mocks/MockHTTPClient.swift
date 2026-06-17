//
//  Created by Vonage on 23/7/25.
//

import Foundation
import VERADomain

public final class MockHTTPClient: HTTPClient {
    public var data = Data()
    public var dataSequence: [Data] = []
    public var shouldThrowError = false
    public var shouldThrowErrorOnCallNumber: Int?
    public var delaySeconds: TimeInterval = 0
    public var callCount = 0
    public var recordedURL: URL!
    public var recordedURLs: [URL] = []
    public var recordedHeaders: [String:String] = [:]
    public var recordedData: Data?
    public var recordedDataSequence: [Data] = []

    public init(
        data: Data = Data(),
        shouldThrowError: Bool = false,
        delaySeconds: TimeInterval = 0,
        callCount: Int = 0,
        recordedURL: URL! = nil,
        recordedData: Data? = nil
    ) {
        self.data = data
        self.shouldThrowError = shouldThrowError
        self.delaySeconds = delaySeconds
        self.callCount = callCount
        self.recordedURL = recordedURL
        self.recordedData = recordedData
    }

    public func get(_ url: URL) async throws -> Data {
        try await recordAndReturn(url: url, data: nil)
    }

    public func post(_ url: URL, additionalHeaders: [String: String] = [:],data: Data) async throws -> Data {
        try await recordAndReturn(url: url, additionalHeaders: additionalHeaders, data: data)
    }

    private func recordAndReturn(url: URL, additionalHeaders: [String: String] = [:], data: Data?) async throws -> Data {
        callCount += 1
        recordedURL = url
        recordedURLs.append(url)
        if let data {
            recordedData = data
            recordedDataSequence.append(data)
        }
        
        additionalHeaders.forEach { (key, value) in
            recordedHeaders = [key: value]
        }

        if delaySeconds > 0 {
            try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
        }

        if shouldThrowError || shouldThrowErrorOnCallNumber == callCount {
            throw MockHTTPError()
        }

        if !dataSequence.isEmpty {
            return dataSequence[min(callCount - 1, dataSequence.count - 1)]
        }
        return self.data
    }
}

public struct MockHTTPError: Error, Equatable {}
