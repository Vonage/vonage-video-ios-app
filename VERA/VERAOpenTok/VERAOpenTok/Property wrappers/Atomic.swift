//
//  Created by Vonage on 2/10/25.
//

import Foundation

@propertyWrapper
public struct Atomic<Value> {
    private let queue = DispatchQueue(
        label: "com.vonage.atomic",
        qos: .userInitiated,
        attributes: .concurrent
    )
    private var value: Value

    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    public var wrappedValue: Value {
        get {
            return queue.sync { value }
        }
        set {
            queue.sync(flags: .barrier) { value = newValue }
        }
    }
}
