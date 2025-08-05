//
//  Created by Vonage on 4/8/25.
//

import Combine
import Foundation
import VERACore

public final class DefaultArchivesRepository: ArchivesRepository {
    private let archivesDataSource: ArchivesDataSource
    private var cache: [String: CurrentValueSubject<[VERACore.Archive], Error>] = [:]
    private var pollingTasks: [String: Task<Void, Never>] = [:]
    private let pollingInterval: TimeInterval = 5

    public init(
        archivesDataSource: ArchivesDataSource
    ) {
        self.archivesDataSource = archivesDataSource
    }

    public func getArchives(
        roomName: VERACore.RoomName
    ) -> AnyPublisher<[VERACore.Archive], Error> {
        let publisher = getPublisher(roomName: roomName)

        // Start polling
        startPolling(for: roomName, publisher: publisher)

        return publisher.eraseToAnyPublisher()
    }

    private func startPolling(
        for roomName: VERACore.RoomName,
        publisher: CurrentValueSubject<[VERACore.Archive], Error>
    ) {
        // Cancel any existing polling task for this room
        pollingTasks[roomName]?.cancel()

        let task = Task {
            repeat {
                do {
                    let archives = try await archivesDataSource.getArchives(roomName: roomName)

                    // Check if task was cancelled
                    guard !Task.isCancelled else { return }

                    publisher.value = archives

                    // Stop polling if all archives are available
                    if allArchivesAvailable(archives) {
                        pollingTasks[roomName] = nil
                        return
                    }

                    // Wait before next poll
                    try await Task.sleep(nanoseconds: 5_000_000_000)  // 5 seconds

                } catch {
                    guard !Task.isCancelled else { return }
                    publisher.send(completion: .failure(error))
                    pollingTasks[roomName] = nil
                    return
                }
            } while !Task.isCancelled
        }

        pollingTasks[roomName] = task
    }

    private func allArchivesAvailable(_ archives: [VERACore.Archive]) -> Bool {
        guard !archives.isEmpty else { return true }
        return archives.allSatisfy { $0.status == .available }
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
        .init(
            id: UUID(uuidString: id) ?? UUID(),
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
