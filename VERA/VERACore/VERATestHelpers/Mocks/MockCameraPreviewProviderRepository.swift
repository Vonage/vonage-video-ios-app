//
//  Created by Vonage on 8/8/25.
//

import Foundation
import VERACore

public final class MockCameraPreviewProviderRepository: CameraPreviewProviderRepository {

    public var publisher: MockVERAPublisher!

    public init(publisher: MockVERAPublisher) {
        self.publisher = publisher
    }

    public func getPublisher() -> any VERACore.VERAPublisher {
        publisher
    }

    public func resetPublisher() {
        publisher = nil
    }
}

public func makeMockCameraPreviewProviderRepository(
    publisher: MockVERAPublisher = .init()
) -> MockCameraPreviewProviderRepository {
    MockCameraPreviewProviderRepository(publisher: publisher)
}
