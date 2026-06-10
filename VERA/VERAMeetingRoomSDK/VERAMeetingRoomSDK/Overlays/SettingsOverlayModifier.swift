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
    
    @StateObject private var feedbackSectionViewModel = FeedbackSectionViewModel()

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .sheet(isPresented: $showFeedbackForm) {
                    FeedbackSectionView(feedbackSectionViewModel: feedbackSectionViewModel)
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

    enum Const {
        static let maxStandardFieldChars = 100
        static let maxDescriptionChars = 1000
    }
    
    init() {
        
    }
}

struct FeedbackSectionView: View {

    @ObservedObject var feedbackSectionViewModel: FeedbackSectionViewModel

    var body: some View {
        List {
            ForEach(feedbackSectionViewModel.feedbackFields.indices, id: \.self) { index in
                let field = feedbackSectionViewModel.feedbackFields[index]
                switch field.type {
                case .text:
                    FeedbackTextFieldView(
                        feedbackFieldViewModel: feedbackSectionViewModel.feedbackFields[index]
                    )
                case .image:
                    FeedbackImageFieldView(
                        feedbackFieldViewModel: feedbackSectionViewModel.feedbackFields[index]
                    )
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

struct FeedbackTextFieldView: View {

    private static let lineHeight: CGFloat = 21

    @ObservedObject var feedbackFieldViewModel: FeedbackFieldViewModel

    var body: some View {
        Section {
            if let maxLineLimit = feedbackFieldViewModel.maxLineLimit {
                LimitedMultilineTextView(
                    text: Binding(
                        get: { feedbackFieldViewModel.value },
                        set: { feedbackFieldViewModel.value = $0 }
                    ),
                    minLines: feedbackFieldViewModel.minLineLimit ?? 1,
                    maxLines: maxLineLimit,
                    maxCharacters: feedbackFieldViewModel.maxChars,
                    lineHeight: Self.lineHeight
                )
            } else {
                TextField("", text: $feedbackFieldViewModel.value, axis: .vertical)
                    .autocorrectionDisabled()
                    .frame(maxHeight: 200)
            }
        } header: {
            Text(feedbackFieldViewModel.title)
        } footer: {
            if feedbackFieldViewModel.isValid == false, let message = feedbackFieldViewModel.validationMessage {
                Text(message)
            } else {
                if let maxChars = feedbackFieldViewModel.maxChars {
                    HStack {
                        Spacer()
                        Text("\(feedbackFieldViewModel.value.count)/\(maxChars)")
                    }
                }
            }
            
            Text(
                feedbackFieldViewModel.footer ?? "")
        }
    }
}

struct FeedbackImageFieldView: View {

    @ObservedObject var feedbackFieldViewModel: FeedbackFieldViewModel

    var body: some View {
        Section {
            TextField("", text: $feedbackFieldViewModel.value)
                .autocorrectionDisabled()
        } header: {
            Text(feedbackFieldViewModel.title)
        } footer: {
            Text(
                feedbackFieldViewModel.footer ?? "")
        }
    }
}
