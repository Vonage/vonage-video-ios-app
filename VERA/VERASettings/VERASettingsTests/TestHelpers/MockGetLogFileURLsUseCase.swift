//
//  Created by Vonage on 23/06/2026.
//

import Foundation

@testable import VERASettings

final class MockGetLogFileURLsUseCase: GetLogFileURLsUseCase {

    var urls: [URL] = []

    func callAsFunction() -> [URL] {
        urls
    }
}
