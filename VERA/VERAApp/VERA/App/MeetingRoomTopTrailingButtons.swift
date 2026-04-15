//
//  Created by Vonage on 30/1/26.
//

import Foundation
import SwiftUI
import VERACommonUI
import VERACore
import VERAMeetingRoom

public final class MeetingRoomTopTrailingButtons {
    static var topTrailingButtons: [ViewGenerator] = {
        [
            .init(
                id: "Speaker",
                content: {
                    ZStack {
                        AudioRoutePickerView()
                            .frame(width: 44, height: 44)
                    }
                })
        ]
    }()
}
