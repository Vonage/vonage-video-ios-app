//
//  Created by Vonage on 13/10/25.
//

import Foundation

/// A lightweight registry for OpenTok plugins used by the call façade.
///
/// `OpenTokPluginRegistry` holds a deduplicated list of plugins that extend call functionality
/// (e.g., chat, CallKit, recording). The registry is typically injected into session creation
/// so plugins can be assigned to each new call.
///
/// ## Overview
///
/// Responsibilities:
/// - Maintain a list of plugins conforming to ``OpenTokPlugin``
/// - Prevent duplicates based on ``OpenTokPluginID/pluginIdentifier``
/// - Provide the registered plugins to the call at creation time
public final class OpenTokPluginRegistry {

    /// The deduplicated list of registered plugins.
    ///
    /// Plugins are identified and deduplicated using their ``OpenTokPluginID/pluginIdentifier``.
    public private(set) var plugins: [any OpenTokPlugin] = []

    /// Creates a registry with an optional initial list of plugins.
    ///
    /// - Parameter plugins: Initial plugins to register. Duplicates (by identifier) will be ignored on later registration.
    public init(plugins: [any OpenTokPlugin] = []) {
        self.plugins = plugins
    }

    /// Registers a plugin if not already present.
    ///
    /// Deduplicates using ``OpenTokPluginID/pluginIdentifier`` to prevent multiple entries of the same plugin.
    ///
    /// - Parameter plugin: The plugin to register.
    public func registerPlugin(plugin: any OpenTokPlugin) {
        if !plugins.contains(where: { $0.pluginIdentifier == plugin.pluginIdentifier }) {
            plugins.append(plugin)
        }
    }
}
