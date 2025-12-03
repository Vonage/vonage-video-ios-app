//
//  Created by Vonage on 7/8/25.
//

import Combine

public typealias LandingPageError = String

public enum LandingPageViewState: Equatable {
    case success(RoomName)
    case content
}

@MainActor
public final class LandingPageViewModel: ObservableObject {

    private let tryJoinRoomUseCase: TryJoinRoomUseCase
    private let tryCreatingANewRoomUseCase: TryCreatingANewRoomUseCase

    @Published public var state: LandingPageViewState = .content
    @Published public var error: AlertItem?

    public init(
        tryJoinRoomUseCase: TryJoinRoomUseCase,
        tryCreatingANewRoomUseCase: TryCreatingANewRoomUseCase
    ) {
        self.tryJoinRoomUseCase = tryJoinRoomUseCase
        self.tryCreatingANewRoomUseCase = tryCreatingANewRoomUseCase
    }

    public func onHandleNewRoom() {
        let name = tryCreatingANewRoomUseCase()
        state = .success(name)
    }

    public func onJoinRoom(_ name: String) {
        Task {
            do {
                try tryJoinRoomUseCase(name)
                await MainActor.run { [weak self] in
                    self?.state = .success(name)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.error = AlertItem.genericError(error.localizedDescription)
                }
            }
        }
    }
}
