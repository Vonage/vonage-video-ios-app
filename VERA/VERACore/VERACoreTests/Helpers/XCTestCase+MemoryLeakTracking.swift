//
//  Created by Vonage on 17/7/25.
//

import Foundation
import XCTest

extension XCTestCase {
    public func trackForMemoryLeaks(
        _ instance: AnyObject,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(
                instance,
                "Instance should have been deallocated. Potential memory leak.",
                file: file,
                line: line)
        }
    }
}
