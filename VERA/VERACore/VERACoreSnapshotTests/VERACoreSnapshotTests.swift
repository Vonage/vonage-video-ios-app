//
//  Created by Vonage on 7/7/25.
//

import XCTest
import SwiftUI
import SnapshotTesting
@testable import VERACore

class VERACoreSnapshotTests: XCTestCase {
    
    // MARK: - Basic Snapshot Tests
    
    func testSimpleText() throws {
        let view = Text("Hello, VERA!")
            .font(.title)
            .padding()
        
        // Correct SwiftUI snapshot syntax - use SwiftUISnapshotLayout
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits), record: SnapshotTestConfig.isRecording)
    }
    
    func testSimpleButton() throws {
        let button = Button("Tap Me") {
            // Action
        }
        .padding()
        
        // Basic button snapshot - using size that fits
        assertSnapshot(of: button, as: .image(layout: .sizeThatFits), record: SnapshotTestConfig.isRecording)
    }
    
    func testFixedSizeView() throws {
        let view = VStack {
            Text("VERA Video Call")
                .font(.title)
            
            Button("Join Call") {
                // Action
            }
            .buttonStyle(BorderedProminentButtonStyle())
        }
        .padding()
        .frame(width: 200, height: 100)
        .background(Color(.systemBackground))
        
        // Test with fixed size
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 200, height: 100)), record: SnapshotTestConfig.isRecording)
    }
}

// MARK: - Configuration

enum SnapshotTestConfig {
    static let isRecording = false  // Set to true to record new snapshots
}
