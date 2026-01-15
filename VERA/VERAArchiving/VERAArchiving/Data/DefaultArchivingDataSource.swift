//
//  Created by Vonage on 14/1/26.
//

import Foundation
import VERADomain

public struct DefaultArchivingDataSource: ArchivingDataSource {
    private let baseURL: URL
    private let httpClient: HTTPClient

    public init(
        baseURL: URL,
        httpClient: HTTPClient
    ) {
        self.baseURL = baseURL
        self.httpClient = httpClient
    }

    public func startArchiving(
        _ request: StartArchivingDataSourceRequest
    ) async throws {

    }

    public func stopArchiving(
        _ request: StopArchivingDataSourceRequest
    ) async throws {

    }
}
