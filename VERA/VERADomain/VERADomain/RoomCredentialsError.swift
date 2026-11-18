//
//  Created by Vonage on 30/06/2026.
//

import Foundation

/// Errors that can occur while fetching room credentials.
public enum RoomCredentialsError: Error, Equatable {
    case sessionKeyExpired
}
