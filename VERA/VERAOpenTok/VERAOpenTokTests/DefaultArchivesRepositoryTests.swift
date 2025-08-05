//
//  Created by Vonage on 5/8/25.
//

import Foundation
import Testing
import VERACore
import VERAOpenTok
import VERATestHelpers

@Suite("Default archives repository tests")
struct DefaultArchivesRepositoryTests {
    
    @Test
    func zero() {
        let sut = makeSUT()
        
        let archives = sut.getArchives(roomName: "heart-of-gold")
    }
    
    // MARK: - Test Helpers
    
    private func makeSUT(
        archivesDataSource: ArchivesDataSource = makeMockArchivesDataSource()
    ) -> DefaultArchivesRepository {
        DefaultArchivesRepository(archivesDataSource: archivesDataSource)
    }
}
