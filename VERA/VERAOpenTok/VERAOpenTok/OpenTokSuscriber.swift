//
//  Created by Vonage on 28/7/25.
//

import Foundation
import OpenTok
import SwiftUI
import VERACore
import Combine

public class OpenTokSuscriber: NSObject {
    let otSuscriber: OTSubscriber
    var cancellables = Set<AnyCancellable>()
    
    var id: String { stream.streamId }
    var stream: OTStream { otSuscriber.stream! }
    var date: Date { stream.creationTime }
    
    @Published public private(set) var audioLevel: Float = 0.0
    @Published public private(set) var videoDimensions = VideoDimensions.default
    @Published public private(set) var participant: Participant
    
    public var aspectRatio: Double { videoDimensions.aspectRatio }

    public var view: AnyView {
        let view = otSuscriber.view!
        let rendererView = UIViewContainer(view: view)

        if aspectRatio >= 1 {
            otSuscriber.viewScaleBehavior = .fill
        } else {
            otSuscriber.viewScaleBehavior = .fit
        }

        return AnyView(rendererView)
    }

    init(suscriber: OTSubscriber) {
        otSuscriber = suscriber
        participant = Participant(
            id: suscriber.stream!.streamId,
            name: suscriber.stream!.name ?? "",
            isMicEnabled: suscriber.stream!.hasAudio,
            isCameraEnabled: suscriber.stream!.hasVideo,
            videoDimensions: VideoDimensions.default,
            creationTime: suscriber.stream!.creationTime,
            view: AnyView(EmptyView()))
        super.init()
    }
    
    func setup() {
        stream
            .publisher(for: \.videoDimensions)
            .removeDuplicates()
            .sink { [weak self] newSize in
                self?.videoDimensions = newSize
                self?.updateParticipant()
            }
            .store(in: &cancellables)
        
        $audioLevel
            .sink { [weak self] _ in
                self?.updateParticipant()
            }
            .store(in: &cancellables)
        
        updateParticipant()
    }
    
    private func updateParticipant() {
        participant = Participant(
            id: id,
            name: stream.name ?? "",
            isMicEnabled: stream.hasAudio,
            isCameraEnabled: stream.hasVideo,
            videoDimensions: videoDimensions,
            creationTime: date,
            view: view
        )
    }
}

extension OpenTokSuscriber: OTSubscriberDelegate {
    // MARK: - Suscriber delegate

    public func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {

    }

    public func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {

    }
}

extension OpenTokSuscriber: OTSubscriberKitAudioLevelDelegate {
    // MARK: Audio levels delegate

    public func subscriber(_ subscriber: OTSubscriberKit, audioLevelUpdated audioLevel: Float) {
        self.audioLevel = audioLevel
    }
}

extension OpenTokSuscriber: OTSubscriberKitCaptionsDelegate {
    // MARK: Audio levels delegate

    public func subscriber(_ subscriber: OTSubscriberKit, caption text: String, isFinal: Bool) {

    }
}
