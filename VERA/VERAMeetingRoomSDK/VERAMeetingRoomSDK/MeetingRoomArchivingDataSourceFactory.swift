//
//  Created by Vonage on 09/06/2026.
//

import Foundation
import VERAArchiving
import VERADomain

public struct MeetingRoomArchivingDataSourceFactoryContext {
    public let baseURL: URL
    public let httpClient: any HTTPClient
    public let archivingStatusDataSource: any ArchivingStatusDataSource

    public init(
        baseURL: URL,
        httpClient: any HTTPClient,
        archivingStatusDataSource: any ArchivingStatusDataSource
    ) {
        self.baseURL = baseURL
        self.httpClient = httpClient
        self.archivingStatusDataSource = archivingStatusDataSource
    }
}

public protocol MeetingRoomArchivingDataSourceFactory {
    func callAsFunction(
        _ context: MeetingRoomArchivingDataSourceFactoryContext
    ) -> any ArchivingDataSource
}

public struct DefaultMeetingRoomArchivingDataSourceFactory:
    MeetingRoomArchivingDataSourceFactory
{
    public init() {}

    public func callAsFunction(
        _ context: MeetingRoomArchivingDataSourceFactoryContext
    ) -> any ArchivingDataSource {
        DefaultArchivingDataSource(
            baseURL: context.baseURL,
            httpClient: context.httpClient)
    }
}
