//
//  Created by Vonage on 22/2/26.
//

import Foundation

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
