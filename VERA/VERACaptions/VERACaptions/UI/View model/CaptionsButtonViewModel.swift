//
//  Created by Vonage on 6/2/26.
//

import Combine
import Foundation
import VERADomain

public final class CaptionsButtonViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    @Published public var state: CaptionsState = .disabled
    
    private let roomName: RoomName
    private let enableCaptionsUseCase: EnableCaptionsUseCase
    private let disableCaptionsUseCase: DisableCaptionsUseCase
    private let captionsStatusDataSource: CaptionsStatusDataSource
    private var initiated = false
    
    public init(
        roomName: RoomName,
        enableCaptionsUseCase: EnableCaptionsUseCase,
        disableCaptionsUseCase: DisableCaptionsUseCase,
        captionsStatusDataSource: CaptionsStatusDataSource
    ) {
        self.roomName = roomName
        self.enableCaptionsUseCase = enableCaptionsUseCase
        self.disableCaptionsUseCase = disableCaptionsUseCase
        self.captionsStatusDataSource = captionsStatusDataSource
    }
    
    public func setup() {
        guard !initiated else { return }
        initiated = true
        
        captionsStatusDataSource.captionsState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.state = status
            }
            .store(in: &cancellables)
    }
    
    public func onTap() {
        switch state {
        case .enabled(_):
            disableCaptionsUseCase()
        case .disabled:
            Task {
                try? await enableCaptionsUseCase(.init(roomName: roomName))
            }
        }
    }
}
