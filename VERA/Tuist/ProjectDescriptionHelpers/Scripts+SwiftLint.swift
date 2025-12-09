import ProjectDescription

extension TargetScript {
    public static var swiftLint: TargetScript {
        .pre(
            script: "${SRCROOT}/../../scripts/swiftlint-xcode.sh",
            name: "SwiftLint",
            basedOnDependencyAnalysis: false
        )
    }
}
