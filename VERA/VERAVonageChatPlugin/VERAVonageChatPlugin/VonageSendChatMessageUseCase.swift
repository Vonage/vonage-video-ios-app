//
//  Created by Vonage on 20/10/25.
//

import Foundation
import VERAChat

public final class VonageSendChatMessageUseCase: SendChatMessageUseCase {

    private let vonageChatPlugin: VonageChatPlugin

    public init(vonageChatPlugin: VonageChatPlugin) {
        self.vonageChatPlugin = vonageChatPlugin
    }

    public func callAsFunction(_ text: String) throws {
        try vonageChatPlugin.sendMessage(text)
    }
}
