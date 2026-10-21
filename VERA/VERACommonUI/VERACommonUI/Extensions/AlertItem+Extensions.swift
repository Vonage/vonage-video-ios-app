//
//  Created by Vonage on 22/12/25.
//

import Foundation
import SwiftUI
import VERADomain

extension AlertItem {
    public var view: Alert {
        if let cancelAction {
            Alert(
                title: Text(title),
                message: Text(message),
                primaryButton: .default(Text(okAction ?? "OK")) {
                    onConfirm?()
                },
                secondaryButton: .cancel(Text(cancelAction))
            )
        } else {
            Alert(
                title: Text(title),
                message: Text(message),
                dismissButton: .default(Text("OK")) {
                    onConfirm?()
                }
            )
        }
    }
}
