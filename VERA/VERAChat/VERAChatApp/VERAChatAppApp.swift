//
//  Created by Vonage on 10/10/25.
//

import SwiftUI
import VERAChat

@main
struct VERAChatAppApp: App {

    @State var messages: [UIChatMessage] = UIChatMessage.sampleMessages

    var body: some Scene {
        WindowGroup {
            ChatPanel(
                messages: messages,
                onSendMessage: { message in
                    addMessage(message)
                }
            )
        }
    }

    func addMessage(_ message: String) {
        messages.insert(
            .init(
                username: "Me",
                message: message,
                date: Date().formatted(date: .omitted, time: .shortened)), at: 0)
    }
}
