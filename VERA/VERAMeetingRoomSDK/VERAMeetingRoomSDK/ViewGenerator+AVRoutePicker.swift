//
//  Created by Vonage on 14/05/2026.
//

import Foundation
import SwiftUI
import VERAMeetingRoom

extension ViewGenerator {
    static func avPicker() -> ViewGenerator {
        .init(
            id: "Speaker",
            content: {
                ZStack {
                    AudioRoutePickerView()
                        .frame(width: 44, height: 44)
                }
            })
    }
}
