//
//  Created by Vonage on 08/06/2026.
//

import VERAArchiving
import VERAE2E
import VERAMeetingRoomSDK

struct E2EMeetingRoomArchivingDataSourceFactory:
    MeetingRoomArchivingDataSourceFactory
{
    func callAsFunction(
        _ context: MeetingRoomArchivingDataSourceFactoryContext
    ) -> any ArchivingDataSource {
        let defaultDataSource = DefaultArchivingDataSource(
            baseURL: context.baseURL,
            httpClient: context.httpClient)
        return E2EArchivingDataSource(
            decorated: defaultDataSource,
            archivingStatusDataSource: context.archivingStatusDataSource)
    }
}
