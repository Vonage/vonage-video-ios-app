//
//  Created by Vonage on 15/7/25.
//

import Foundation

extension String {
    func getInitials(limit: Int = 2) -> String {
        let names = self.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        let selected: [String]
        switch names.count {
        case 1:
            selected = [names.first!]
        case 2...:
            selected = [names.first!, names.last!]
        default:
            selected = []
        }
        return
            selected
            .prefix(limit)
            .compactMap { $0.first?.uppercased() }
            .joined()
    }
}
