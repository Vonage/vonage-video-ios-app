//
//  Created by Vonage on 29/7/25.
//

import Foundation
import VERACore
import Combine

class MockCall: VERACore.CallFacade {
    let _eventsPublisher = CurrentValueSubject<VERACore.SessionEvent, Never>(.idle)
    lazy var eventsPublisher: AnyPublisher<VERACore.SessionEvent, Never> = _eventsPublisher.eraseToAnyPublisher()
    
    let _participantsPublisher = CurrentValueSubject<[VERACore.Participant], Never>([])
    lazy var participantsPublisher: AnyPublisher<[VERACore.Participant], Never> = _participantsPublisher.eraseToAnyPublisher()
    
    let _statePublisher = CurrentValueSubject<VERACore.SessionState, Never>(SessionState.default)
    lazy var statePublisher: AnyPublisher<VERACore.SessionState, Never> = _statePublisher.eraseToAnyPublisher()
    
    init() {}
    
    func connect() {
    }
    
    func disconnect() {
    }
    
    func toggleLocalVideo() {
    }
    
    func toggleLocalAudio() {
    }   
}
