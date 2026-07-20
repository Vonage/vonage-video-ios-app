//
//  Created by Vonage on 02/07/2026.
//

import SwiftUI

struct ActiveCallFooter: View {
    let isInActiveCall: Bool
    let description: String

    var body: some View {
        if isInActiveCall {
            ActiveCallWarningText()
        } else {
            Text(description)
        }
    }
}
