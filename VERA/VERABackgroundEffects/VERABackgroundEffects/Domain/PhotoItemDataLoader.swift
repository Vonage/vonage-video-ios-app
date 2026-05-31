//
//  Created by Vonage on 01/06/2026.
//

import Foundation
import PhotosUI
import SwiftUI

/// Abstraction for loading image data, allowing `PhotosPickerItem`
/// to be replaced with test doubles in unit tests.
public protocol PhotoItemDataLoader: Sendable {
    func loadImageData() async throws -> Data?
}

extension PhotosPickerItem: PhotoItemDataLoader {
    public func loadImageData() async throws -> Data? {
        try await loadTransferable(type: Data.self)
    }
}
