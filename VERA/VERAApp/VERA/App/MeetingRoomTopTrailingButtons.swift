//
//  Created by Vonage on 30/1/26.
//

import Foundation
import SwiftUI
import VERACommonUI
import VERACore

public final class MeetingRoomTopTrailingButtons {
    static var topTrailingButtons: [ViewGenerator] = {
        [
            .init(
                id: "Speaker",
                content: {
                    ZStack {
                        VERACommonUIAsset.Images.audioMidLine.swiftUIImage
                        AudioRoutePickerView()
                            .frame(width: 32, height: 32)
                            .opacity(0.1)
                    }
                })
        ]
    }()
}
