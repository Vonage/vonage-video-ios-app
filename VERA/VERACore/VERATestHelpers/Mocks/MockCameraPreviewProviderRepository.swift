//
//  Created by Vonage on 8/8/25.
//

import Combine
import Foundation
import VERACore
import VERADomain

public final class MockCameraPreviewProviderRepository: CameraPreviewProviderRepository {

    public enum RecordedActions {
        case get, reset
    }

    public var publisher: MockVERAPublisher!

    public var actions: [RecordedActions] = []

    private let resetSubject = PassthroughSubject<Void, Never>()
    public var didResetPublisher: AnyPublisher<Void, Never> {
        resetSubject.eraseToAnyPublisher()
    }

    public init(publisher: MockVERAPublisher) {
        self.publisher = publisher
    }

    public func getPublisher() -> any VERAPublisher {
        actions.append(.get)
        return publisher
    }

    public func resetPublisher() {
        actions.append(.reset)
        publisher = nil
        resetSubject.send(())
    }
}

public func makeMockCameraPreviewProviderRepository(
    publisher: MockVERAPublisher = .init()
) -> MockCameraPreviewProviderRepository {
    MockCameraPreviewProviderRepository(publisher: publisher)
}
