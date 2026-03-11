//
//  Created by Vonage on 02/03/2026.
//

public final class NullAdvancedSettingsUseCase: PublisherAdvancedSettingsUseCase {

    public init() {}

    public func callAsFunction() -> PublisherAdvancedSettings {
        .init()
    }
}
