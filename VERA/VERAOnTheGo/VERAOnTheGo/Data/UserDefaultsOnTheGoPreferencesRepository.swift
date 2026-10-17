//
//  Created by Vonage on 17/10/26.
//

import Combine
import Foundation

/// ``OnTheGoPreferencesRepository`` persisted in `UserDefaults`.
public final class UserDefaultsOnTheGoPreferencesRepository: OnTheGoPreferencesRepository {

    /// The UserDefaults key backing ``suggestWhenMoving``.
    static let suggestWhenMovingKey = "onTheGo.suggestWhenMoving"

    private let userDefaults: UserDefaults
    private let subject: CurrentValueSubject<Bool, Never>

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.subject = CurrentValueSubject(Self.read(from: userDefaults))
    }

    public var suggestWhenMoving: Bool {
        get { Self.read(from: userDefaults) }
        set {
            userDefaults.set(newValue, forKey: Self.suggestWhenMovingKey)
            subject.send(newValue)
        }
    }

    public var suggestWhenMovingPublisher: AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    private static func read(from userDefaults: UserDefaults) -> Bool {
        userDefaults.object(forKey: suggestWhenMovingKey) as? Bool ?? true
    }
}
