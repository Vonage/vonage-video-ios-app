//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

struct ParticipantsBadgeButton: View {
    
    private let participantsCount: Int
    private let onToggleParticipants: () -> Void
    
    init(participantsCount: Int, onToggleParticipants: @escaping () -> Void) {
        self.participantsCount = participantsCount
        self.onToggleParticipants = onToggleParticipants
    }
    
    var body: some View {
        ControlButton(
            isActive: true,
            iconName: "person.2.fill",
            action: onToggleParticipants)
    }
}

#Preview {
    ParticipantsBadgeButton(participantsCount: 25, onToggleParticipants: {})
}
