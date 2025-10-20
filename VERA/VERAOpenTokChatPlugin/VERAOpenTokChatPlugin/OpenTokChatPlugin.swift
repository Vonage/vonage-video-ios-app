//
//  Created by Vonage on 13/10/25.
//

import Foundation
import VERAChat
import VERAOpenTok

public final class OpenTokChatPlugin: OpenTokPlugin {

    public enum SignalType: String {
        case chat
    }

    public enum Error: Swift.Error {
        case missingChannel
    }

    public var channel: (any VERAOpenTok.OpenTokSignalChannel)?
    private var username: String = ""
    public let repository: ChatMessagesRepository

    fileprivate static let jsonEncoder = JSONEncoder()
    fileprivate static let jsonDecoder = JSONDecoder()

    public init(repository: ChatMessagesRepository = DefaultChatMessagesRepository()) {
        self.repository = repository
    }

    public func handleSignal(_ signal: VERAOpenTok.OpenTokSignal) {
        guard signal.type == SignalType.chat.rawValue else { return }

        do {
            let chatMessage = try signal.toChatMessage()
            repository.addMessage(chatMessage)
        } catch {
            print(error.localizedDescription)
        }
    }

    public func callDidStart(_ userInfo: [String: Any]) {
        username = userInfo.username
    }

    public func callDidEnd() {
        cleanUp()
    }

    func sendMessage(_ message: String) throws {
        guard let channel = channel else {
            throw Error.missingChannel
        }

        let openTokMessage = OpenTokChatMessage(
            participantName: username,
            text: message)

        let signal = OutgoingSignal(
            type: SignalType.chat.rawValue,
            payload: try openTokMessage.toJSONString())
        try channel.emitSignal(signal)
    }

    private func cleanUp() {
        repository.clearMessages()
    }
}

extension [String: Any] {
    fileprivate var username: String {
        self[OpenTokCallParams.username.rawValue] as? String ?? ""
    }
}

public struct OpenTokChatMessage: Codable {
    public let participantName: String
    public let text: String

    public init(participantName: String, text: String) {
        self.participantName = participantName
        self.text = text
    }
}

extension VERAOpenTok.OpenTokSignal {

    public func toChatMessage(date: Date = Date()) throws -> ChatMessage {
        guard let signalData = data, !signalData.isEmpty else {
            throw ChatMappingError.missingData
        }

        let jsonData = Data(signalData.utf8)

        do {
            let openTokMessage = try OpenTokChatPlugin.jsonDecoder.decode(OpenTokChatMessage.self, from: jsonData)

            let username = openTokMessage.participantName
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let message = openTokMessage.text
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !username.isEmpty else {
                throw ChatMappingError.invalidParticipantName
            }

            guard !message.isEmpty else {
                throw ChatMappingError.emptyMessage
            }

            return ChatMessage(
                username: username,
                message: message,
                date: date)

        } catch DecodingError.dataCorrupted(_) {
            throw ChatMappingError.invalidJSON
        } catch is DecodingError {
            throw ChatMappingError.invalidJSON
        } catch {
            throw error
        }
    }
}

public enum ChatMappingError: LocalizedError {
    case missingData
    case invalidJSON
    case invalidParticipantName
    case emptyMessage

    public var errorDescription: String? {
        switch self {
        case .missingData:
            return "Signal data is missing or empty"
        case .invalidJSON:
            return "Invalid JSON format in signal data"
        case .invalidParticipantName:
            return "Participant name is empty or invalid"
        case .emptyMessage:
            return "Message content is empty"
        }
    }
}

extension OpenTokChatMessage {
    public func toJSONString() throws -> String {
        let jsonData = try OpenTokChatPlugin.jsonEncoder.encode(self)

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ChatMappingError.invalidJSON
        }

        return jsonString
    }
}
