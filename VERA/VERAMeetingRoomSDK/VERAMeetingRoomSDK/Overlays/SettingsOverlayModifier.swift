//
//  Created by Vonage on 21/04/2026.
//

import SwiftUI
import VERASettings

// MARK: - Settings Overlay Modifier

struct SettingsOverlayModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var showSettings: Bool
    let statsOverlayViewModel: StatsOverlayViewModel?
    let container: MeetingRoomSDKContainer

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .sheet(isPresented: $showSettings) {
                    SettingsSheetContent(factory: container.settingsFactory)
                        .presentationDetents([.large])
                }
                .overlay {
                    if let statsViewModel = statsOverlayViewModel {
                        container.settingsFactory.makeStatsOverlayView(viewModel: statsViewModel)
                    }
                }
        } else {
            content
        }
    }
}


struct FeedbackFormOverlayModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var showFeedbackForm: Bool
    let statsOverlayViewModel: StatsOverlayViewModel?
    let container: MeetingRoomSDKContainer

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .sheet(isPresented: $showFeedbackForm) {
                    FeedbackSheetContent()
                        .presentationDetents([.large])
                }
        } else {
            content
        }
    }
}

enum FeedbackFieldType {
    case text, image
}

protocol FieldValidatable {
    var isValid: Bool { get }
    var validationMessage: String? { get }
}
class FeedbackFieldViewModel: ObservableObject, FieldValidatable  {
    let maxChars: Int?
    let minLineLimit: Int?
    let maxLineLimit: Int?
    let title: String
    let key: String
    let footer: String?
    @Published var value: String
    var type: FeedbackFieldType
    var isRequired: Bool
    
    init(maxChars: Int? = nil, minLineLimit: Int? = nil, maxLineLimit: Int? = nil, title: String, key: String, footer: String? = nil, type: FeedbackFieldType, value: String = "", isRequired: Bool = true) {
        self.maxChars = maxChars
        self.minLineLimit = minLineLimit
        self.maxLineLimit = maxLineLimit
        self.title = title
        self.key = key
        self.footer = footer
        self.type = type
        self.value = value
        self.isRequired = isRequired
    }
    
    var isValid: Bool {
        if type == .text, let maxChars {
            return value.count <= maxChars
        }
        
        if isRequired {
            return value.isEmpty == false
        }
        return true
    }
    
    var validationMessage: String? {
        var message: String?
        if isRequired && value.isEmpty != false {
            message = key + " is required"
        }
        
        if type == .text, let maxChars {
            if message == nil {
                message = key
            } else {
                message? += " and"
            }
            
            message = (message ?? "") + " must be less than \(maxChars) characters"
            
        }
        return message
    }
}

extension FeedbackFieldViewModel: Identifiable {
    var id: String { key }
}

class FeedbackSectionViewModel: ObservableObject {
    
    enum Const {
        static let maxStandardFieldChars = 100
        static let maxDescriptionChars = 1000
    }

    let title = "Report isue"
    @Published var feedbackFields = [
        FeedbackFieldViewModel(
            maxChars: 100, minLineLimit: 2, maxLineLimit: 5,
            title: "When you noticed this issue, what where you trying to do?",
            key: "Title", type: .text
        ),
        FeedbackFieldViewModel(
            maxChars: 100, minLineLimit: 2, maxLineLimit: 5,
            title: "Tell us your name", key: "Name", type: .text
        ),
        FeedbackFieldViewModel(
            maxChars: 1000, minLineLimit: 5, maxLineLimit: 10,
            title: "Describe your issue", key: "Description",
            footer: "Please do not include any sensitive information", type: .text
        ),
        FeedbackFieldViewModel(title: "", key: "Image", type: .image, isRequired: false),
    ]
    
    init() {

    }
    
    func onSubmit() {
        
    }
}
