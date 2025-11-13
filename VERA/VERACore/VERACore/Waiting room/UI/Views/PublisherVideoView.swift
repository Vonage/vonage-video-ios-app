//
//  Created by Vonage on 15/7/25.
//

import SwiftUI
import VERACommonUI

public struct PublisherVideoView: View {
    let videoView: AnyView?

    var hasVideo: Bool {
        videoView != nil
    }

    public init(videoView: AnyView?) {
        self.videoView = videoView
    }

    public var body: some View {
        ZStack {
            VERACommonUIAsset.Colors.videoBackground.swiftUIColor
                .ignoresSafeArea()
            if let videoView = videoView {
                videoView.frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    PublisherVideoView(videoView: nil)
}
