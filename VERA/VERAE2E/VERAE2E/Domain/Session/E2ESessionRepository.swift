//
//  Created by Vonage on 7/6/26.
//

import VERADomain
import VERAVonage

public final class E2ESessionRepository: SessionRepository {
    public private(set) var currentCall: (any CallFacade)?
    private let publisherSettings: PublisherSettings
    private let plugins: [any VonagePlugin]

    public init(
        publisherSettings: PublisherSettings = .init(),
        plugins: [any VonagePlugin] = []
    ) {
        self.publisherSettings = publisherSettings
        self.plugins = plugins
    }

    public func createSession(_ credentials: RoomCredentials) async throws -> any CallFacade {
        if let currentCall {
            return currentCall
        }

        let call = E2ECallFacade(
            publisherSettings: publisherSettings,
            plugins: plugins,
            credentials: credentials)
        currentCall = call
        return call
    }

    public func clearSession() {
        currentCall = nil
    }
}
