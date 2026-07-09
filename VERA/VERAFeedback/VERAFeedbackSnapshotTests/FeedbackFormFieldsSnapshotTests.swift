//
//  Created by Vonage on 15/06/2026.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERAFeedback

@Suite("Feedback Form Fields Snapshot Tests")
@MainActor
struct FeedbackFormFieldsSnapshotTests {

    private let isRecording = false  // Set to true to record new snapshots

    @Test("FeedbackTextFieldView - valid and error states")
    func textFieldStates() {
        let validField = FeedbackFieldViewModel(
            maxChars: 100, title: "Title", key: "Title", type: .text, value: "Joining a call", isRequired: true
        )
        let errorField = FeedbackFieldViewModel(
            maxChars: 100, title: "Name", key: "Name", type: .text, value: "", isRequired: true
        )

        let validView = FeedbackTextFieldSnapshotHost(field: validField, showValidationErrors: false)
        let errorView = FeedbackTextFieldSnapshotHost(field: errorField, showValidationErrors: true)

        assertSnapshot(
            of: AnyView(validView),
            as: .image(precision: 0.99, layout: .fixed(width: 360, height: 140)),
            named: "text-field-valid",
            record: isRecording
        )
        assertSnapshot(
            of: AnyView(errorView),
            as: .image(precision: 0.99, layout: .fixed(width: 360, height: 160)),
            named: "text-field-error",
            record: isRecording
        )
    }

    @Test("FeedbackInfoFieldView renders info text")
    func infoFieldRenders() {
        let field = FeedbackFieldViewModel(
            title: "", key: "Info", type: .info,
            value: "Please do not include any sensitive information.", isRequired: false
        )
        let view = FeedbackInfoFieldView(feedbackFieldViewModel: field)

        assertSnapshot(
            of: AnyView(view),
            as: .image(precision: 0.99, layout: .fixed(width: 360, height: 80)),
            named: "info-field",
            record: isRecording
        )
    }

    @Test("FeedbackImageFieldView - empty and with preview")
    func imageFieldStates() {
        let emptyField = FeedbackFieldViewModel(
            title: "", key: "Image", type: .image,
            value: "A screenshot will help us better understand the issue. (optional)",
            isRequired: false
        )
        let filledField = FeedbackFieldViewModel(
            title: "", key: "Image", type: .image,
            value: "A screenshot will help us better understand the issue. (optional)",
            isRequired: false
        )
        filledField.attachedImage = FeedbackSnapshotHelpers.makeTestImage()

        assertSnapshot(
            of: AnyView(FeedbackImageFieldView(feedbackFieldViewModel: emptyField, showValidationErrors: false)),
            as: .image(precision: 0.99, layout: .fixed(width: 360, height: 220)),
            named: "image-field-empty",
            record: isRecording
        )
        assertSnapshot(
            of: AnyView(FeedbackImageFieldView(feedbackFieldViewModel: filledField, showValidationErrors: false)),
            as: .image(precision: 0.99, layout: .fixed(width: 360, height: 360)),
            named: "image-field-with-preview",
            record: isRecording
        )
    }
}

@MainActor
private struct FeedbackTextFieldSnapshotHost: View {
    @FocusState private var focusedFieldIndex: Int?
    let field: FeedbackFieldViewModel
    let showValidationErrors: Bool

    var body: some View {
        FeedbackTextFieldView(
            feedbackFieldViewModel: field,
            showValidationErrors: showValidationErrors,
            fieldIndex: 0,
            focusedFieldIndex: $focusedFieldIndex
        )
        .padding()
        .background(Color.feedbackFormBackground)
    }
}
