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

    public var channel: (any VERAOpenTok.OpenTokSignalChannel)?
    private var username: String = ""
    public let repository: ChatMessagesRepository

    static let jsonEncoder = JSONEncoder()
    static let jsonDecoder = JSONDecoder()

    public init(repository: ChatMessagesRepository = DefaultChatMessagesRepository()) {
        self.repository = repository
    }

    public func registered() {}

    public func unregistered() {}

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
        repository.clearMessages()
        repository.onSendMessage = sendMessage
    }

    public func callDidEnd() {
        cleanUp()
    }

    private func sendMessage(_ message: String) {
        do {
            let openTokMessage = OpenTokChatMessage(
                participantName: username,
                text: message
            )

            let signal = OutgoingSignal(
                type: SignalType.chat.rawValue,
                payload: try openTokMessage.toJSONString())
            try channel?.emitSignal(signal)
        } catch {
            print(error.localizedDescription)
        }
    }

    private func cleanUp() {
        repository.onSendMessage = nil
    }
}

extension [String: Any] {
    fileprivate var username: String {
        self[OpenTokCallParams.username.rawValue] as? String ?? ""
    }
}

struct OpenTokChatMessage: Codable {
    let participantName: String
    let text: String
}

extension OpenTokSignal {

    fileprivate func toChatMessage() throws -> ChatMessage {
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
                date: Date()
            )

        } catch DecodingError.dataCorrupted(_) {
            throw ChatMappingError.invalidJSON
        } catch is DecodingError {
            throw ChatMappingError.invalidJSON
        } catch {
            throw error
        }
    }
}

private enum ChatMappingError: LocalizedError {
    case missingData
    case invalidJSON
    case invalidParticipantName
    case emptyMessage

    var errorDescription: String? {
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
    func toJSONString() throws -> String {
        let jsonData = try OpenTokChatPlugin.jsonEncoder.encode(self)

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ChatMappingError.invalidJSON
        }

        return jsonString
    }
}
