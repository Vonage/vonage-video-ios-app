//
//  Created by Vonage on 7/8/25.
//

import Combine

public typealias LandingPageError = String

public enum LandingPageViewState: Equatable {
    case loading
    case error(LandingPageError)
    case success(RoomName)
    case content
}

public final class LandingPageViewModel {

    private let tryJoinRoomUseCase: TryJoinRoomUseCase
    private let tryCreatingANewRoomUseCase: TryCreatingANewRoomUseCase

    @Published public var state: LandingPageViewState = .content

    public init(
        tryJoinRoomUseCase: TryJoinRoomUseCase,
        tryCreatingANewRoomUseCase: TryCreatingANewRoomUseCase
    ) {
        self.tryJoinRoomUseCase = tryJoinRoomUseCase
        self.tryCreatingANewRoomUseCase = tryCreatingANewRoomUseCase
    }

    public func onHandleNewRoom() {
        let name = tryCreatingANewRoomUseCase.invoke()
        state = .success(name)
    }

    public func onJoinRoom(_ name: String) {
        state = .loading

        Task {
            do {
                try tryJoinRoomUseCase.invoke(name)
                await MainActor.run {
                    state = .success(name)
                }
            } catch {
                await MainActor.run {
                    state = .error(error.localizedDescription)
                }
            }
        }
    }
}
