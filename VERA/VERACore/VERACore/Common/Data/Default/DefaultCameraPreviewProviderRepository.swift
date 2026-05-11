//
//  Created by Vonage on 8/8/25.
//

import Combine
import Foundation
import VERADomain

public final class DefaultCameraPreviewProviderRepository: CameraPreviewProviderRepository {

    private let publisherFactory: PublisherFactory
    private let advancedSettingsProvider: () -> PublisherAdvancedSettings?
    private var publisher: VERAPublisher?

    private let resetSubject = PassthroughSubject<Void, Never>()
    public var didResetPublisher: AnyPublisher<Void, Never> {
        resetSubject.eraseToAnyPublisher()
    }

    /// - Parameter advancedSettingsProvider: Optional closure that supplies
    ///   the current `PublisherAdvancedSettings` to apply when building the
    ///   preview publisher. The default returns `nil` so existing call-sites
    ///   keep their previous behaviour (SDK capture defaults).
    public init(
        publisherFactory: PublisherFactory,
        advancedSettingsProvider: @escaping () -> PublisherAdvancedSettings? = { nil }
    ) {
        self.publisherFactory = publisherFactory
        self.advancedSettingsProvider = advancedSettingsProvider
    }

    public func getPublisher() throws -> VERAPublisher {
        if let publisher = publisher {
            return publisher
        }
        let settings = PublisherSettings(
            scaleBehavior: .fit,
            advancedSettings: advancedSettingsProvider()
        )
        let producedPublisher = try publisherFactory.make(settings)
        let decorated = MicLevelPublisherDecorator(wrapping: producedPublisher)
        self.publisher = decorated
        return decorated
    }

    public func resetPublisher() {
        publisher?.cleanUp()
        publisher = nil
        resetSubject.send(())
    }
}
