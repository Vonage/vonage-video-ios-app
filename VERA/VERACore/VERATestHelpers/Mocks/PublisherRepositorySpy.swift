//
//  Created by Vonage on 4/11/25.
//

import Foundation
import VERACore
import VERADomain

public class PublisherRepositorySpy: PublisherRepository {

    public enum PublisherAction: Equatable {
        case get, reset
        case recreate(PublisherSettings)
    }

    public var actions: [PublisherAction] = []

    public func getPublisher() -> any VERAPublisher {
        actions.append(.get)
        return MockVERAPublisher()
    }

    public func resetPublisher() {
        actions.append(.reset)
    }

    public func recreatePublisher(_ settings: PublisherSettings) {
        actions.append(.recreate(settings))
    }
}

public func makePublisherRepositorySpy() -> PublisherRepositorySpy {
    .init()
}

public class MockPublisherAdvancedSettingsUseCase: PublisherAdvancedSettingsUseCase {

    public init() {}

    public func callAsFunction() async -> PublisherAdvancedSettings {
        .init()
    }
}

public func makePublisherAdvancedSettingsUseCase() -> MockPublisherAdvancedSettingsUseCase {
    .init()
}
