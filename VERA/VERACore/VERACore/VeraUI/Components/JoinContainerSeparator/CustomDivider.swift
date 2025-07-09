//
//  Created by Vonage on 9/7/25.
//

import SwiftUI

struct CustomDivider: View {
    let color: Color
    let height: CGFloat
    
    init(color: Color = Color(.vGray3), height: CGFloat = 1) {
        self.color = color
        self.height = height
    }
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: height)
    }
}
