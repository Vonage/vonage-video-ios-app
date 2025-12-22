//
//  Created by Vonage on 22/12/25.
//

import Foundation
import SwiftUI
import VERADomain

extension AlertItem {
    public var view: Alert {
        Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: .default(Text("OK")) {
                onConfirm?()
            }
        )
    }
}
