//
//  Created by Vonage on 13/10/25.
//

import Foundation
import VERAOpenTok
import VERAChat

public final class OpenTokChatPlugin: OpenTokPlugin {
    
    public enum SignalType: String {
        case chat
    }
    
    public var channel: (any VERAOpenTok.OpenTokSignalChannel)?
    
    public let repository: ChatMessagesRepository
    
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
    
    public func callDidStart() {
        repository.clearMessages()
    }
    
    public func callDidEnd() {}
}

struct OpenTokChatMessage: Decodable {
    let participantName: String
    let text: String
}

private extension OpenTokSignal {
    
    func toChatMessage() throws -> ChatMessage {
        guard let signalData = data, !signalData.isEmpty else {
            throw ChatMappingError.missingData
        }
        
        let jsonData = Data(signalData.utf8)
        let decoder = JSONDecoder()
        
        do {
            let openTokMessage = try decoder.decode(OpenTokChatMessage.self, from: jsonData)
            
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
