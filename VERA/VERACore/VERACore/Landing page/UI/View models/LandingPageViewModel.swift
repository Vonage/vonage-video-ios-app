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

    @Published public var state: LandingPageViewState = .content

    public init(tryJoinRoomUseCase: TryJoinRoomUseCase) {
        self.tryJoinRoomUseCase = tryJoinRoomUseCase
    }

    public func onHandleNewRoom() {

    }

    public func onJoinRoom(_ name: String) {
        state = .loading

        Task {
            do {
                try await tryJoinRoomUseCase.invoke(name)
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
