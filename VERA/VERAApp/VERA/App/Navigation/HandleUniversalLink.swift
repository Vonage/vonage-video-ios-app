//
//  Created by Vonage on 6/10/25.
//

import Foundation
import VERACore
import VERADomain

public final class HandleUniversalLink {

    private let baseURL: URL
    private let navigator: Navigator

    public init(baseURL: URL, navigator: Navigator) {
        self.baseURL = baseURL
        self.navigator = navigator
    }

    @MainActor
    public func callAsFunction(_ url: URL) {
        guard let roomIdentifier = url.getRoomIdentifier(from: baseURL) else { return }

        if let sessionKeyIdentifier = roomIdentifier as? SessionKeyRoomIdentifier,
            SessionKeyParser.isExpired(sessionKeyIdentifier.sessionKey) {
            navigator.showAlert(.expiredLinkError())
            return
        }

        navigator.go(to: .waitingRoom(roomIdentifier.roomName))
    }
}
