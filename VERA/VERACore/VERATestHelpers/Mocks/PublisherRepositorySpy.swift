//
//  PublisherRepositorySpy.swift
//  VERACoreTests
//
//  Created by Ivan Ornes on 4/11/25.
//

import Foundation
import VERACore

public class PublisherRepositorySpy: PublisherRepository {

    public enum PublisherAction {
        case get, reset
        case recreate(VERACore.PublisherSettings)
    }

    public var actions: [PublisherAction] = []

    public func getPublisher() -> any VERACore.VERAPublisher {
        actions.append(.get)
        return MockVERAPublisher()
    }

    public func resetPublisher() {
        actions.append(.reset)
    }

    public func recreatePublisher(_ settings: VERACore.PublisherSettings) {
        actions.append(.recreate(settings))
    }
}

public func makePublisherRepositorySpy() -> PublisherRepositorySpy {
    .init()
}
