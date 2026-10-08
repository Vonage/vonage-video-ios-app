import ProjectDescription

extension TargetScript {
    /// Regenerates `SPMAssets+VERACommonUI.swift` from the Tuist-generated
    /// `TuistAssets+VERACommonUI.swift` as a pre-build phase.
    ///
    /// This keeps the SPM asset accessors in sync with the asset catalog on
    /// every Xcode build, so they never drift when someone runs a plain
    /// `tuist generate` + build without going through `Scripts/builder.sh`.
    /// It complements (does not replace) the equivalent step in `builder.sh`.
    ///
    /// The `inputPaths`/`outputPaths` make the phase incremental: Xcode only
    /// reruns it when the Tuist-generated assets change.
    public static func generateSPMAssets() -> TargetScript {
        .pre(
            script: """
                if [ "${RUN_SPM_ASSETS_CODEGEN:-YES}" = "NO" ]; then
                  echo "SPM asset codegen skipped (RUN_SPM_ASSETS_CODEGEN=NO)"
                  exit 0
                fi
                ${SRCROOT}/../../scripts/generate-spm-assets-xcode.sh
                """,
            name: "Generate SPM Assets",
            inputPaths: [
                "${SRCROOT}/Derived/Sources/TuistAssets+VERACommonUI.swift"
            ],
            outputPaths: [
                "${SRCROOT}/VERACommonUI/Generated/SPMAssets+VERACommonUI.swift"
            ],
            basedOnDependencyAnalysis: true,
        )
    }
}
