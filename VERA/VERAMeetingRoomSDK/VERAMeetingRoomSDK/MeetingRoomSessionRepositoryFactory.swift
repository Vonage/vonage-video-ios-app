//
//  Created by Vonage on 09/06/2026.
//

import Foundation
import VERADomain
import VERAVonage

public struct MeetingRoomSessionRepositoryFactoryContext {
    public let publisherSettings: PublisherSettings
    public let sessionFactory: VonageSessionFactory
    public let roomCredentialsRepository: any RoomCredentialsRepository
    public let sessionKeyWriter: any SessionKeyWriter
    public let publisherRepository: any PublisherRepository
    public let pluginRegistry: VonagePluginRegistry
    public let statsCollector: any StatsCollector

    public init(
        publisherSettings: PublisherSettings,
        sessionFactory: VonageSessionFactory,
        roomCredentialsRepository: any RoomCredentialsRepository,
        sessionKeyWriter: any SessionKeyWriter,
        publisherRepository: any PublisherRepository,
        pluginRegistry: VonagePluginRegistry,
        statsCollector: any StatsCollector
    ) {
        self.publisherSettings = publisherSettings
        self.sessionFactory = sessionFactory
        self.roomCredentialsRepository = roomCredentialsRepository
        self.sessionKeyWriter = sessionKeyWriter
        self.publisherRepository = publisherRepository
        self.pluginRegistry = pluginRegistry
        self.statsCollector = statsCollector
    }
}

public protocol MeetingRoomSessionRepositoryFactory {
    func callAsFunction(
        _ context: MeetingRoomSessionRepositoryFactoryContext
    ) -> any SessionRepository
}

public struct DefaultMeetingRoomSessionRepositoryFactory:
    MeetingRoomSessionRepositoryFactory
{
    public init() {}

    public func callAsFunction(
        _ context: MeetingRoomSessionRepositoryFactoryContext
    ) -> any SessionRepository {
        VonageSessionRepository(
            sessionProvider: VonageSessionProvider(
                sessionFactory: context.sessionFactory,
                roomCredentialsRepository: context.roomCredentialsRepository,
                sessionKeyWriter: context.sessionKeyWriter),
            publisherRepository: context.publisherRepository,
            pluginRegistry: context.pluginRegistry,
            statsCollector: context.statsCollector)
    }
}
