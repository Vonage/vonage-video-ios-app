import ProjectDescription
import ProjectDescriptionHelpers

let workspace = Workspace(
    name: "VERA",
    projects: ["."],
    // Aggregated test schemes (one per xcodebuild destination) so CI runs the whole
    // suite with a single invocation per destination instead of one per module scheme.
    schemes: VERATestSchemes.all(),
    fileHeaderTemplate: .file("FileHeaderTemplate.swift")
)
