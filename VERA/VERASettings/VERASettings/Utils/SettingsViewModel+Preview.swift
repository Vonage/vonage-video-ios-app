//
//  Created by Vonage on 4/3/26.
//

#if DEBUG
@preconcurrency import Combine
import Foundation
import VERADomain

// MARK: - Mock Repository

final class PreviewSettingsRepository: PublisherSettingsRepository {
    
    private let subject = CurrentValueSubject<PublisherSettingsPreferences, Never>(.default)
    
    var preferencesPublisher: AnyPublisher<PublisherSettingsPreferences, Never> {
        subject.eraseToAnyPublisher()
    }
    
    func getPreferences() async -> PublisherSettingsPreferences {
        subject.value
    }
    
    func save(_ preferences: PublisherSettingsPreferences) async {
        subject.send(preferences)
    }
    
    func reset() async {
        subject.send(.default)
    }
    
    func saveNoAsync(_ preferences: PublisherSettingsPreferences) {
        subject.send(preferences)
    }
}

// MARK: - Preview Instances

extension SettingsViewModel {
    
    static var preview: SettingsViewModel {
        SettingsViewModel(repository: PreviewSettingsRepository())
    }
    
    static var previewWithStatsEnabled: SettingsViewModel {
        let repo = PreviewSettingsRepository()
        var prefs = PublisherSettingsPreferences.default
        prefs.senderStatsEnabled = true
        return SettingsViewModel(repository: repo, settingsPreference: prefs)
    }
}
#endif
