//
//  Created by Vonage on 4/8/25.
//

import Combine
import Foundation
import VERACore

public final class DefaultArchivesRepository: ArchivesRepository {
    private let archivesDataSource: ArchivesDataSource
    private var cache: [String: CurrentValueSubject<[VERACore.Archive], Error>] = [:]

    public init(
        archivesDataSource: ArchivesDataSource
    ) {
        self.archivesDataSource = archivesDataSource
    }
    
    public func getArchives(
        roomName: VERACore.RoomName
    ) async -> AnyPublisher<[VERACore.Archive], Error> {
        let publisher = getPublisher(roomName: roomName)
        
        do {
            let archives = try await archivesDataSource.getArchives(roomName: roomName)
            publisher.value = archives
        } catch {
            publisher.send(completion: .failure(error))
        }
        
        return publisher.eraseToAnyPublisher()
    }
    
    
    private func getPublisher(
        roomName: VERACore.RoomName
    ) -> CurrentValueSubject<[VERACore.Archive], Error> {
        if let publisher = cache[roomName] {
            return publisher
        }
        let publisher = CurrentValueSubject<[VERACore.Archive], Error>([])
        cache[roomName] = publisher
        return publisher
    }
}

public struct RemoteArchivesResponse: Decodable {
    public let archives: [RemoteArchive]
    public let status: Int
}

public struct RemoteArchive: Decodable {
    public let id: String
    public let status: String
    public let name: String
    public let reason: String?
    public let sessionId: String
    public let applicationId: String
    public let createdAt: Int
    public let size: Int
    public let duration: Int
    public let outputMode: String
    public let streamMode: String
    public let hasAudio: Bool
    public let hasVideo: Bool
    public let hasTranscription: Bool
    public let sha256sum: String
    public let password: String
    public let updatedAt: Int
    public let multiArchiveTag: String
    public let event: String
    public let resolution: String
    public let url: String?
    
    var toDomain: VERACore.Archive {
        .init(id: UUID(uuidString: id) ?? UUID(),
              name: name,
              createdAt: Date(),
              status: ArchiveStatus(rawValue: status),
              url: url?.toURL)
    }
}

extension String {
    var toURL: URL? {
        URL(string: self)
    }
}
