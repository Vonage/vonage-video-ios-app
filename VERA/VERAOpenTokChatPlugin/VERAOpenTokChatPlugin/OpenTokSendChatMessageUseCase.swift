//
//  Created by Vonage on 20/10/25.
//

import Foundation
import VERAChat

public final class OpenTokSendChatMessageUseCase: SendChatMessageUseCase {

    private let openTokChatPlugin: OpenTokChatPlugin

    public init(openTokChatPlugin: OpenTokChatPlugin) {
        self.openTokChatPlugin = openTokChatPlugin
    }

    public func callAsFunction(_ text: String) throws {
        try openTokChatPlugin.sendMessage(text)
    }
}
