//
//  Created by Vonage on 31/05/2026.
//

import Foundation
import VERADomain

/// Persists the selected `VideoEffect` to `UserDefaults`.
///
/// On load, validates that `.backgroundImage` paths still exist on disk;
/// falls back to `.none` if the referenced file was deleted.
public final class DefaultVideoEffectRepository: VideoEffectRepository {

    private static let key = "com.vonage.vera.selectedVideoEffect"
    private let defaults: UserDefaults
    private let fileManager: FileManager

    public init(
        defaults: UserDefaults = .standard,
        fileManager: FileManager = .default
    ) {
        self.defaults = defaults
        self.fileManager = fileManager
    }

    public func save(_ effect: VideoEffect) {
        guard let data = try? JSONEncoder().encode(effect) else { return }
        defaults.set(data, forKey: Self.key)
    }

    public func load() -> VideoEffect {
        guard let data = defaults.data(forKey: Self.key),
            let effect = try? JSONDecoder().decode(VideoEffect.self, from: data)
        else { return .none }

        if case .backgroundImage(_, let path) = effect,
            !fileManager.fileExists(atPath: path)
        {
            save(.none)
            return .none
        }

        return effect
    }
}
