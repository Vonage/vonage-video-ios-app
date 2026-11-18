//
//  Created by Vonage on 23/7/25.
//

import Foundation
import VERADomain

public final class MockHTTPClient: HTTPClient {
    private struct State: Sendable {
        var data: Data = Data()
        var dataSequence: [Data] = []
        var shouldThrowError: Bool = false
        var shouldThrowErrorOnCallNumber: Int? = nil
        var delaySeconds: TimeInterval = 0
        var callCount: Int = 0
        var recordedURL: URL? = nil
        var recordedURLs: [URL] = []
        var recordedHeaders: [String: String] = [:]
        var recordedData: Data? = nil
        var recordedDataSequence: [Data] = []
    }

    private let state = TestLockedValue(State())

    public var data: Data {
        get { state.withValue { $0.data } }
        set { state.withValue { $0.data = newValue } }
    }

    public var dataSequence: [Data] {
        get { state.withValue { $0.dataSequence } }
        set { state.withValue { $0.dataSequence = newValue } }
    }

    public var shouldThrowError: Bool {
        get { state.withValue { $0.shouldThrowError } }
        set { state.withValue { $0.shouldThrowError = newValue } }
    }

    public var shouldThrowErrorOnCallNumber: Int? {
        get { state.withValue { $0.shouldThrowErrorOnCallNumber } }
        set { state.withValue { $0.shouldThrowErrorOnCallNumber = newValue } }
    }

    public var delaySeconds: TimeInterval {
        get { state.withValue { $0.delaySeconds } }
        set { state.withValue { $0.delaySeconds = newValue } }
    }

    public var callCount: Int {
        get { state.withValue { $0.callCount } }
        set { state.withValue { $0.callCount = newValue } }
    }

    public var recordedURL: URL! {
        get { state.withValue { $0.recordedURL } }
        set { state.withValue { $0.recordedURL = newValue } }
    }

    public var recordedURLs: [URL] {
        get { state.withValue { $0.recordedURLs } }
        set { state.withValue { $0.recordedURLs = newValue } }
    }

    public var recordedHeaders: [String: String] {
        get { state.withValue { $0.recordedHeaders } }
        set { state.withValue { $0.recordedHeaders = newValue } }
    }

    public var recordedData: Data? {
        get { state.withValue { $0.recordedData } }
        set { state.withValue { $0.recordedData = newValue } }
    }

    public var recordedDataSequence: [Data] {
        get { state.withValue { $0.recordedDataSequence } }
        set { state.withValue { $0.recordedDataSequence = newValue } }
    }
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

    public func get(_ url: URL, additionalHeaders: [String: String] = [:]) async throws -> Data {
        try await recordAndReturn(url: url, additionalHeaders: additionalHeaders, data: nil)
    }

    public func post(_ url: URL, additionalHeaders: [String: String] = [:], data: Data) async throws -> Data {
        try await recordAndReturn(url: url, additionalHeaders: additionalHeaders, data: data)
    }

    private func recordAndReturn(url: URL, additionalHeaders: [String: String] = [:], data: Data?) async throws -> Data
    {
        let response = state.withValue { state -> (Data, Bool, TimeInterval) in
            state.callCount += 1
            state.recordedURL = url
            state.recordedURLs.append(url)
            if let data {
                state.recordedData = data
                state.recordedDataSequence.append(data)
            }
            for (key, value) in additionalHeaders {
                state.recordedHeaders = [key: value]
            }
            let shouldThrow = state.shouldThrowError || state.shouldThrowErrorOnCallNumber == state.callCount
            let result =
                state.dataSequence.isEmpty
                ? state.data
                : state.dataSequence[min(state.callCount - 1, state.dataSequence.count - 1)]
            return (result, shouldThrow, state.delaySeconds)
        }
        if response.2 > 0 {
            try await Task.sleep(nanoseconds: UInt64(response.2 * 1_000_000_000))
        }
        if response.1 {
            throw MockHTTPError()
        }
        return response.0
    }
}

public struct MockHTTPError: Error, Equatable {}
