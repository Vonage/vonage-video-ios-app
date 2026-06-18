//
//  Created by Vonage on 10/06/2026.
//

import Combine
import Foundation
import VERADomain

enum FeedbackFormConstants {
    static let maxStandardFieldChars = 100
    static let maxDescriptionChars = 1000
}

@MainActor
class FeedbackFormViewModel: ObservableObject {

    static let titleKey = String(localized: "Title")
    static let titleFieldText = String(localized: "When you noticed this issue, what were you trying to do?")
    static let nameKey = String(localized: "Name")
    static let nameFieldText = String(localized: "Tell us your name")
    static let descriptionKey = String(localized: "Description")
    static let descriptionFieldText = String(localized: "Describe your issue")
    static let infoKey = String(localized: "Info")
    static let infoFieldText = String(localized: "Please do not include any sensitive information.")
    static let imageKey = String(localized: "Image")
    static let imageFieldText = String(
        localized: "A screenshot will help us better understand the issue. (optional)")

    static let formTitle = String(localized: "Report issue")

    let title = formTitle
    @Published var isLoading = false
    @Published var toast: ToastItem?
    @Published var feedbackResult: FeedbackReportResult?
    @Published var showValidationErrors = false
    @Published var feedbackFields = [
        FeedbackFieldViewModel(
            maxChars: FeedbackFormConstants.maxStandardFieldChars,
            title: titleFieldText,
            key: titleKey,
            type: .text
        ),
        FeedbackFieldViewModel(
            maxChars: FeedbackFormConstants.maxStandardFieldChars,
            title: nameFieldText,
            key: nameKey,
            type: .text
        ),
        FeedbackFieldViewModel(
            maxChars: FeedbackFormConstants.maxDescriptionChars,
            title: descriptionFieldText,
            key: descriptionKey,
            type: .text
        ),
        FeedbackFieldViewModel(
            title: "",
            key: infoKey,
            type: .info,
            value: infoFieldText,
            isRequired: false
        ),
        FeedbackFieldViewModel(
            title: "",
            key: imageKey,
            type: .image,
            value: imageFieldText,
            isRequired: false
        ),
    ]

    private let feedbackReportUseCase: FeedbackReportUseCase
    private let sessionDebugInfoProvider: () -> FeedbackSessionDebugInfo

    init(
        feedbackReportUseCase: FeedbackReportUseCase,
        sessionDebugInfoProvider: @escaping () -> FeedbackSessionDebugInfo = { .empty }
    ) {
        self.feedbackReportUseCase = feedbackReportUseCase
        self.sessionDebugInfoProvider = sessionDebugInfoProvider
    }

    var isValid: Bool {
        feedbackFields.allSatisfy(\.isValid)
    }

    func debugDump() -> String {
        FeedbackDebugDumpBuilder.debugDump(session: sessionDebugInfoProvider())
    }

    func onSubmit() {
        showValidationErrors = true
        guard isValid else { return }

        Task { @MainActor in
            await submitReport()
        }
    }

    @MainActor
    private func submitReport() async {
        isLoading = true
        defer {
            isLoading = false
        }
        do {
            feedbackResult = try await feedbackReportUseCase(
                .init(
                    title: fieldValue(forKey: String(localized: "Title")),
                    name: fieldValue(forKey: String(localized: "Name")),
                    issue: fieldValue(forKey: String(localized: "Description")),
                    image: imageField()?.attachedImage,
                    debugDump: debugDump()
                )
            )
        } catch {
            toast = .init(message: String(localized: "Something failed, please try again"), mode: .failure)
        }
    }

    private func fieldValue(forKey key: String) -> String {
        feedbackFields.first { $0.key == key }?.value.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func imageField() -> FeedbackFieldViewModel? {
        feedbackFields.first { $0.type == .image }
    }
}
