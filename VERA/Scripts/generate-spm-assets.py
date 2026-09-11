#!/usr/bin/env python3
"""
Generate SPMAssets+VERACommonUI.swift from the Tuist-generated
TuistAssets+VERACommonUI.swift.

Why this exists
---------------
VERACommonUI is built two ways:
  * Tuist   -> Derived/Sources/TuistAssets+VERACommonUI.swift is auto-generated
              on every `tuist generate` from the .xcassets catalog.
  * SPM     -> VERACommonUI/Generated/SPMAssets+VERACommonUI.swift is used
              instead (guarded by `#if SWIFT_PACKAGE`).

The SPM file used to be maintained by hand, which caused it to drift from the
asset catalog (e.g. `accent` / `onAccent` colors went missing and broke the SPM
build and snapshot tests). This script derives the SPM file from the Tuist
output so the two never diverge again.

Both files share an identical body (the `VERACommonUIAsset` accessors and the
implementation-detail types, all using `Bundle.module`). Only the header and
import block differ, plus the `#if SWIFT_PACKAGE` wrapper. This script reuses
the shared body verbatim and rewraps it.

Run from the VERA/ directory (invoked by Scripts/builder.sh after
`tuist generate`):

    python3 Scripts/generate-spm-assets.py
"""

import os
import sys

TUIST_ASSETS = "VERACommonUI/Derived/Sources/TuistAssets+VERACommonUI.swift"
SPM_ASSETS = "VERACommonUI/VERACommonUI/Generated/SPMAssets+VERACommonUI.swift"

BODY_START_MARKER = "// MARK: - Asset Catalogs"
FOOTER_MARKERS = ("// swiftformat:enable all", "// swiftlint:enable all")

HEADER = """// swiftlint:disable:this file_name
// swiftlint:disable all
// swift-format-ignore-file
// swiftformat:disable all
//
// SPM-compatible asset accessors for VERACommonUI.
// Mirrors the Tuist-generated TuistAssets+VERACommonUI.swift API
// so that source code works unchanged under both build systems.
//
// This file is compiled ONLY when building with Swift Package Manager.
// During Tuist builds, the equivalent code is auto-generated in Derived/Sources/.
//
// DO NOT EDIT MANUALLY — regenerate via Scripts/generate-spm-assets.py
// (runs automatically as part of Scripts/builder.sh, after `tuist generate`).

#if SWIFT_PACKAGE

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

"""

FOOTER = """
#endif // SWIFT_PACKAGE

// swiftlint:enable all
// swiftformat:enable all
"""


def reindent_asset_enum(lines: list) -> list:
    """Normalize indentation of the `VERACommonUIAsset` accessor enum.

    The Tuist/SwiftGen template under-indents the first member of every nested
    enum (2 spaces instead of 4), e.g.:

        public enum Colors {
        public static let vGray0 = ...   // <- wrong, should be 4 spaces
          public static let vGray1 = ...

    This region only contains nested enums, `public static let` accessors and
    closing braces (no strings with braces, no compiler directives), so we can
    safely recompute indentation from brace nesting (2 spaces per level). Only
    the `VERACommonUIAsset` enum is touched; the hand-formatted
    implementation-detail types below it are left untouched.
    """
    try:
        start = next(
            i for i, line in enumerate(lines)
            if line.strip().startswith("public enum VERACommonUIAsset")
        )
    except StopIteration:
        return lines

    result = lines[:start]
    depth = 0
    entered = False
    i = start
    while i < len(lines):
        stripped = lines[i].strip()
        # Closing braces at the start of a line belong to the outer level.
        lead_closes = len(stripped) - len(stripped.lstrip("}"))
        indent_depth = max(depth - lead_closes, 0)
        result.append(("  " * indent_depth + stripped) if stripped else "")
        depth += stripped.count("{") - stripped.count("}")
        entered = entered or depth > 0
        i += 1
        if entered and depth == 0:
            break

    result.extend(lines[i:])
    return result


def extract_body(source: str) -> str:
    """Extract the shared accessor body from the Tuist-generated file.

    Returns everything from the `// MARK: - Asset Catalogs` marker up to (but
    not including) the trailing swiftlint/swiftformat `enable` footer, with the
    `VERACommonUIAsset` enum re-indented consistently.
    """
    lines = source.splitlines()

    try:
        start = next(i for i, line in enumerate(lines) if line.strip() == BODY_START_MARKER)
    except StopIteration:
        print(f"❌ Error: '{BODY_START_MARKER}' not found in {TUIST_ASSETS}")
        sys.exit(1)

    # Trim trailing blank lines and the enable-footer comments.
    end = len(lines)
    while end > start:
        stripped = lines[end - 1].strip()
        if stripped == "" or stripped in FOOTER_MARKERS:
            end -= 1
        else:
            break

    body_lines = reindent_asset_enum(lines[start:end])
    body = "\n".join(body_lines).rstrip("\n")
    if "public enum VERACommonUIAsset" not in body:
        print(f"❌ Error: extracted body does not contain VERACommonUIAsset accessors")
        sys.exit(1)
    return body


def main() -> None:
    if not os.path.exists(TUIST_ASSETS):
        print(f"❌ Error: {TUIST_ASSETS} not found.")
        print("   Run `tuist generate` first so the Tuist assets are available.")
        sys.exit(1)

    with open(TUIST_ASSETS, "r") as f:
        source = f.read()

    body = extract_body(source)
    output = HEADER + body + "\n" + FOOTER

    os.makedirs(os.path.dirname(SPM_ASSETS), exist_ok=True)

    previous = None
    if os.path.exists(SPM_ASSETS):
        with open(SPM_ASSETS, "r") as f:
            previous = f.read()

    if previous == output:
        print("✅ SPMAssets+VERACommonUI.swift already up to date")
        return

    with open(SPM_ASSETS, "w") as f:
        f.write(output)

    print("✅ Generated SPMAssets+VERACommonUI.swift from TuistAssets")


if __name__ == "__main__":
    main()
