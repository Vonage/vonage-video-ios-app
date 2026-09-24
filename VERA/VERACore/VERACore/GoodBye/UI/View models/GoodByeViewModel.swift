//
//  Created by Vonage on 30/7/25.
//

import Combine
import Foundation
import Observation
import VERADomain

public typealias GoodByeError = String

public struct GoodByeNavigation {
    public let onReenter: () -> Void
    public let onReturnToLanding: () -> Void

    public init(
        onReenter: @escaping () -> Void,
        onReturnToLanding: @escaping () -> Void
    ) {
        self.onReenter = onReenter
        self.onReturnToLanding = onReturnToLanding
    }
}

@Observable
public final class GoodByeViewModel {
    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()
    public let roomName: RoomName
    @ObservationIgnored
    private let userRepository: UserRepository
    @ObservationIgnored
    private let goodByeNavigation: GoodByeNavigation

    @MainActor public var error: AlertItem?

    init(
        roomName: RoomName,
        userRepository: UserRepository,
        goodByeNavigation: GoodByeNavigation
    ) {
        self.roomName = roomName
        self.userRepository = userRepository
        self.goodByeNavigation = goodByeNavigation
    }

    public func onReenter() {
        goodByeNavigation.onReenter()
    }

    public func onReturnToLanding() {
        goodByeNavigation.onReturnToLanding()
    }
}
