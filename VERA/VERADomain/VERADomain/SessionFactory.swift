//
//  Created by Vonage on 30/7/25.
//

import Foundation

@MainActor
public protocol SessionFactory: Sendable {
    associatedtype Session
    func make(_ credentials: RoomCredentials) throws -> Session
}
