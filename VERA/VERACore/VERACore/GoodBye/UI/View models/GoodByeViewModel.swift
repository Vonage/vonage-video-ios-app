//
//  Created by Vonage on 30/7/25.
//

import Combine
import Foundation
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

public final class GoodByeViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    public let roomName: RoomName
    private let joinRoomUseCase: JoinRoomUseCase
    private let userRepository: UserRepository
    private let goodByeNavigation: GoodByeNavigation

    @MainActor @Published public var error: AlertItem?

    init(
        roomName: RoomName,
        joinRoomUseCase: JoinRoomUseCase,
        userRepository: UserRepository,
        goodByeNavigation: GoodByeNavigation
    ) {
        self.roomName = roomName
        self.joinRoomUseCase = joinRoomUseCase
        self.userRepository = userRepository
        self.goodByeNavigation = goodByeNavigation
    }

    @BackgroundActor
    public func joinRoom() async {
        do {
            let username = try await userRepository.get()?.name ?? ""
            let request = JoinRoomRequest(roomName: roomName, userName: username)
            try await joinRoomUseCase(request)
        } catch {
            Task { @MainActor [weak self] in
                self?.error = AlertItem.genericError(error.localizedDescription)
            }
        }
    }

    public func onReenter() {
        Task { [weak self] in
            guard let self else { return }
            await joinRoom()
            await MainActor.run { [weak self] in
                self?.goodByeNavigation.onReenter()
            }
        }
    }

    public func onReturnToLanding() {
        goodByeNavigation.onReturnToLanding()
    }
}
