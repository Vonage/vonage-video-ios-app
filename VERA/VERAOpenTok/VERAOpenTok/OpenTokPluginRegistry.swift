//
//  Created by Vonage on 13/10/25.
//

import Foundation

public final class OpenTokPluginRegistry {

    public private(set) var plugins: [any OpenTokPlugin] = []

    public init(plugins: [any OpenTokPlugin] = []) {
        self.plugins = plugins
    }

    public func registerPlugin(plugin: any OpenTokPlugin) {
        if !plugins.contains(where: { $0.id == plugin.id }) {
            plugins.append(plugin)
        }
    }
}
