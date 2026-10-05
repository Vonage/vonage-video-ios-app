//
//  Created by Vonage on 14/05/2026.
//

import Foundation
import SwiftUI
import VERACommonUI
import VERAMeetingRoom

extension ViewGenerator {
    static func avPicker() -> ViewGenerator {
        .init(
            id: AudioRoutePickerView.viewID,
            content: {
                AudioRoutePickerView.button()
            })
    }
}
