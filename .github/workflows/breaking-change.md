---
description: |
  This workflow analyzes pull requests that modify dependency files and detects
  breaking changes. It compares old and new package versions, researches changelogs
  and release notes, and posts a summary comment on the PR with a breakdown of
  safe updates vs potentially breaking changes.

on:
  pull_request:
    types: [opened, synchronize]
    paths:
      - "Package.swift"
      - "Package.resolved"
      - "Podfile"
      - "Podfile.lock"
      - "Cartfile"
      - "Cartfile.resolved"

permissions:
  contents: read
  pull-requests: read

network: defaults

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

A pull request has been opened or updated that modifies one or more Swift dependency files.

## Your Task

### Step 1 - Identify changed packages

- Read the diff of the dependency files in PR number ${{ github.event.pull_request.number }}.
- List every package whose version has changed (added, removed, or bumped).
- For each package, note the old version and the new version.
- Detect the package manager used: Swift Package Manager (Package.swift / Package.resolved), CocoaPods (Podfile / Podfile.lock), or Carthage (Cartfile / Cartfile.resolved).

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

Post a comment on PR number ${{ github.event.pull_request.number }} with:

- A table listing each changed package, package manager, old version, new version, bump type, and whether breaking changes were found
- For each package with breaking changes: what changed, the impact, and migration steps
- A list of safe updates with no detected breaking changes
- If no dependency files were changed, call the noop tool with a message explaining no changes were detected

## Style

- Be concise and developer-friendly 🔍
- Use emojis moderately for clarity (✅ safe, ⚠️ breaking)
- If you cannot find changelog information for a package, say so explicitly rather than guessing
- Do not modify any files in the repository - only post a comment
