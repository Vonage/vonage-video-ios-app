//
//  Created by Vonage on 15/7/25.
//

import SwiftUI

extension String {
    func getParticipantColor() -> Color {
        let colorMap: [Color] = [
            Color(red: 0.96, green: 0.26, blue: 0.21),  // #f44336
            Color(red: 0.38, green: 0.49, blue: 0.54),  // #607d8b
            Color(red: 0.61, green: 0.15, blue: 0.69),  // #9c27b0
            Color(red: 0.40, green: 0.23, blue: 0.72),  // #673ab7
            Color(red: 0.25, green: 0.32, blue: 0.71),  // #3f51b5
            Color(red: 0.13, green: 0.58, blue: 0.95),  // #2196f3
            Color(red: 1.00, green: 0.34, blue: 0.13),  // #ff5722
            Color(red: 0.00, green: 0.74, blue: 0.83),  // #00bcd4
            Color(red: 1.00, green: 0.76, blue: 0.03),  // #ffc107
            Color(red: 0.30, green: 0.69, blue: 0.31),  // #4caf50
        ]
        let asciiSum = self.unicodeScalars.map { Int($0.value) }.reduce(0, +)
        return colorMap[asciiSum % colorMap.count]
    }
}
