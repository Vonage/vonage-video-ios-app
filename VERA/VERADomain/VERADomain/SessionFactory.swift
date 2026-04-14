//
//  Created by Vonage on 30/7/25.
//

import Foundation

public protocol SessionFactory {
    associatedtype Session
    func make(_ credentials: RoomCredentials) throws -> Session
}
