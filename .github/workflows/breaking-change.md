---
description: |
  This workflow analyzes pull requests that update Swift dependencies (SPM, CocoaPods, Carthage),
  compares package versions, and posts a comment summarizing safe updates and any breaking
  changes with migration steps.

on:
  pull_request:
    types: [opened, synchronize]
    branches:
      - develop

permissions:
  contents: read
  pull-requests: read

network: defaults

runs-on-slim: ubuntu-24.04

tools:
  github:
    lockdown: false
    min-integrity: none
  web-fetch:
  web-search:

safe-outputs:
  add-comment:
    hide-older-comments: true
---

# Breaking Change Detector

A pull request has been opened or updated.

## Your Task

### Step 1 - Identify changed packages

- Read the diff of the dependency files in PR number ${{ github.event.pull_request.number }}.
- Look for changes in: Package.swift, Package.resolved, Podfile, Podfile.lock, Cartfile, Cartfile.resolved.
- List every package whose version has changed (added, removed, or bumped).
- For each package, note the old version and the new version.
- Detect the package manager used: Swift Package Manager (Package.swift / Package.resolved), CocoaPods (Podfile / Podfile.lock), or Carthage (Cartfile / Cartfile.resolved).
- If no dependency files were changed, call the noop tool with the message "No dependency changes detected in this PR" and stop.

### Step 2 - Classify the version bump

For each changed package, determine the type of version bump:

- Major (e.g. 1.x.x to 2.x.x) - highest risk of breaking changes
- Minor (e.g. 1.2.x to 1.3.x) - may include deprecations
- Patch (e.g. 1.2.3 to 1.2.4) - usually safe

### Step 3 - Research breaking changes

For each package with a major or minor bump:

- Search the web for the package changelog or release notes between the old and new versions.
- Look specifically for:
  - Removed or renamed Swift APIs, protocols, or types
  - Changed method signatures or return types
  - Dropped iOS / macOS / Swift version support
  - Objective-C interoperability changes
  - Behavior changes that could silently break existing code
  - Migration guides mentioned in release notes

### Step 4 - Post a PR comment

- If breaking changes were found, post a comment on PR number ${{ github.event.pull_request.number }} with:
  - A table listing each changed package, package manager, old version, new version, bump type, and whether breaking changes were found
  - For each package with breaking changes: what changed, the impact, and migration steps
- If no breaking changes were found, post a comment saying "✅ No breaking changes detected in this PR's dependency updates"

## Style

- Be concise and developer-friendly 🔍
- Use emojis moderately for clarity (✅ safe, ⚠️ breaking)
- If you cannot find changelog information for a package, say so explicitly rather than guessing
- Do not modify any files in the repository - only post a comment
