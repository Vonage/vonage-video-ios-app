//
//  Created by Vonage on 20/10/25.
//

import Foundation

public protocol SendChatMessageUseCase {
    func callAsFunction(_ text: String) throws
}
