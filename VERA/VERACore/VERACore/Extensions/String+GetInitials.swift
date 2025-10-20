//
//  Created by Vonage on 15/7/25.
//

import Foundation

extension String {
    public func getInitials(limit: Int = 2) -> String {
        return splitName()
            .compactMap { $0 }
            .prefix(limit)
            .map { String($0).uppercased() }
            .joined()
    }
    
    private func splitName() -> [Character?] {
        let names = self.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .compactMap { $0.first }
            .filter { $0.isLetter || $0.isNumber }
        
        switch names.count {
        case 1:
            return [names.first]
        case 2...:
            return [names.first, names.last]
        default:
            return [nil]
        }
    }
}
