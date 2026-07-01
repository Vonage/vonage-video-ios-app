//
//  Created by Vonage on 7/6/26.
//

import Foundation

public enum E2EConfiguration {
    public static let enabledArgument = "VERA_E2E_MOCKS"
    public static let failEndpointArgument = "VERA_E2E_FAIL_ENDPOINT"

    public static var isEnabled: Bool {
        launchValue(for: enabledArgument) == "1"
    }

    static var failedEndpoint: E2EEndpoint? {
        launchValue(for: failEndpointArgument).flatMap(E2EEndpoint.init(rawValue:))
    }

    private static func launchValue(for key: String) -> String? {
        if let value = ProcessInfo.processInfo.environment[key], !value.isEmpty {
            return value
        }

        if let value = UserDefaults.standard.string(forKey: key), !value.isEmpty {
            return value
        }

        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-\(key)"),
            arguments.indices.contains(arguments.index(after: index))
        else {
            return nil
        }

        return arguments[arguments.index(after: index)]
    }
}
