import ProjectDescription

extension TargetScript {
    public static func swiftLint(targetName: String) -> TargetScript {
        .pre(
            script: """
                if [ "${RUN_SWIFTLINT}" = "NO" ]; then
                  echo "SwiftLint skipped (RUN_SWIFTLINT=NO)"
                  exit 0
                fi
                ${SRCROOT}/../../scripts/swiftlint-xcode.sh
                """,
            name: "SwiftLint",
            inputPaths: [
                "${SRCROOT}/../../../.swiftlint.yml",
                "${SRCROOT}/\(targetName)/**/*.swift",
            ],
            outputPaths: [
                "${DERIVED_FILE_DIR}/swiftlint-\(targetName).timestamp"
            ],
            basedOnDependencyAnalysis: true,
        )
    }
}
