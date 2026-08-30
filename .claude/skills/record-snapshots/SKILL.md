---
name: record-snapshots
description: Re-record snapshot test reference images the right way — LFS pull, flip isRecording, run the right scheme on iPhone 17 non-parallel, flip back, verify diffs. Use whenever snapshot tests fail with image diffs, the user changed UI and needs new baselines, mentions __Snapshots__, record mode, or reference images, or a snapshot suite fails on a fresh clone.
---

# Re-recording Snapshot Tests

Snapshot tests use pointfree's swift-snapshot-testing with Swift Testing suites. Recording is controlled **per test file** by a constant at the top:

```swift
private let isRecording = false  // Set to true to record new snapshots
```

That constant is passed as `record: isRecording` into `assertSnapshot`. The repo convention is `precision: 0.99`, device layouts like `.device(config: .iPhone13)` / `.iPadPro12_9` / `.fixed(width:height:)`, and light/dark via `@Test(arguments:)` + `.environment(\.colorScheme, _)`. Match these when touching assertions. (There's a `SnapshotTestHelper` in VERACoreSnapshotTests that docs mention — it's dead code with zero call sites; real tests call `assertSnapshot` directly.)

## Step 0: Rule out a fake failure

Before recording anything, check whether the *references* are the problem:

- **LFS pointers**: `.lfsconfig` sets `skipSmudge = true`, so on a fresh clone every `__Snapshots__/*.png` is a text pointer and *all* snapshot tests fail with nonsense diffs. Check and fix:
  ```bash
  head -c 100 "$(find VERA -path '*__Snapshots__*' -name '*.png' | head -1)"
  ```
  If it prints `version https://git-lfs...` → run `git lfs pull` and re-run the tests. Do not record over pointer files.
- A failure only in some variants (e.g. only Dark) after a real UI change is legitimate — proceed.

## Step 1: Flip record mode

Set `isRecording = true` in **only** the failing test file(s) — not repo-wide. Find the file from the failing suite name; snapshots live next to the test file: `.../<TestDir>/__Snapshots__/<SuiteName>/<testName>.<named>.png`.

## Step 2: Run the suite (recording)

Simulator is always **iPhone 17** (no OS pin), and snapshot runs must be non-parallel (rendering determinism). From repo root:

```bash
xcodebuild test \
  -workspace VERA/VERA.xcworkspace \
  -scheme <Module>SnapshotTests \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -parallel-testing-enabled NO \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO | xcpretty
```

(`xcpretty` optional — drop the pipe if not installed.) Scheme = the failing module's `<Module>SnapshotTests`. To touch just one suite, add `-only-testing:<Module>SnapshotTests/<SuiteTypeName>` — the Swift **type** name, not the `@Suite("...")` display string.

A recording run **fails by design** ("Record mode is on" / newly-recorded failures) — that's success for this step; the PNGs were written.

## Step 3: Flip back and verify

1. Set `isRecording = false` again. **Never leave `record: true` behind** — SwiftLint excludes snapshot test dirs, and the pre-push hook only checks formatting, so nothing automated will catch it. Grep before finishing:
   ```bash
   grep -rn "isRecording = true\|record: true" VERA --include="*.swift" | grep -i snapshot
   ```
2. Re-run the same command — all tests must now pass green.
3. Inspect what changed: `git status` / `git diff --stat` on the `__Snapshots__` dirs, and **open the changed PNGs** (Read tool renders them) to confirm the new images show the intended UI change and nothing else drifted. Unexpectedly changed files = a side effect worth flagging, not committing.
4. Commit the PNGs together with the code change; they're LFS-tracked automatically via `.gitattributes`.

## Notes

- CI runs all snapshot targets through the aggregate `VERASnapshotTests-iOS` scheme with the same destination + `-parallel-testing-enabled NO`, so local green on the module scheme predicts CI.
- If many modules need re-recording after a design-token change, do them module-by-module — flipping a global env-var switch isn't the repo convention, and per-file flags keep the blast radius reviewable.
