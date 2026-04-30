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
  issues: read
  pull-requests: read

network: defaults

runs-on-slim: ubuntu-24.04

tools:
  github:
    lockdown: false
    min-integrity: none
  web-fetch:

safe-outputs:
  add-comment:
    hide-older-comments: true
---

# Breaking Change Detector

A pull request has been opened or updated.

## Posting on this PR (critical)

GitHub Actions does **not** publish PR comments from ordinary agent text or from read-only GitHub tools. The workflow only posts when you invoke the **Safe Outputs `add_comment`** tool (sometimes exposed as `add_comment` in the agent tool list). You **must** call that tool once per run with the full Markdown body for PR ${{ github.event.pull_request.number }}.

- Using **noop** does **not** add a visible comment on the PR thread (it only logs to the workflow run). Do **not** use noop when you want reviewers to see the result on the PR—use **`add_comment`** instead.
- After you call **`add_comment`**, do not call noop.

## Your Task

### Step 1 - Identify changed packages

- Read the diff of the dependency files in PR number ${{ github.event.pull_request.number }}.
- Look for changes in: Package.swift, Package.resolved, Podfile, Podfile.lock, Cartfile, Cartfile.resolved.
- List every package whose version has changed (added, removed, or bumped).
- For each package, note the old version and the new version.
- Detect the package manager used: Swift Package Manager (Package.swift / Package.resolved), CocoaPods (Podfile / Podfile.lock), or Carthage (Cartfile / Cartfile.resolved).
- If no dependency files were changed, call **`add_comment`** on this PR with a short summary that includes: "No dependency changes detected in this PR" and a clear verdict line **"✅ Safe to merge"** (with respect to dependency breaking-change risk only). Then stop.

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

### Step 4 - Post via `add_comment` (required)

Call **`add_comment`** once on PR ${{ github.event.pull_request.number }} with Markdown that includes:

1. A one-line **verdict** at the top:
   - If no breaking changes were identified in dependency updates: **"✅ Safe to merge"** (dependency/breaking-change check only; always mention this scope).
   - If breaking changes were found or changelog/research was inconclusive for a risky bump: **"⚠️ Review required before merge"** (and explain why).

2. **If dependency files changed**: a table with each changed package, package manager, old version, new version, bump type, and whether breaking changes were found.

3. **If breaking changes were found**: for each affected package, brief notes on impact and migration steps.

4. **If no breaking changes were found** (but deps did change): state explicitly that no breaking changes were detected in the researched release notes, plus **"✅ Safe to merge"** for this workflow’s scope.

Do not modify repository files. Do not rely on narrating a comment in chat—only **`add_comment`** publishes to the PR.

## Style

- Be concise and developer-friendly 🔍
- Use emojis moderately for clarity (✅ safe, ⚠️ breaking)
- If you cannot find changelog information for a package, say so explicitly rather than guessing
