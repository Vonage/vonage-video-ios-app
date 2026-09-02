---
inclusion: fileMatch
fileMatchPattern: '**/*SnapshotTests/**'
---

# Re-recording Snapshot Tests

Snapshot tests use pointfree's swift-snapshot-testing with Swift Testing suites. Recording is
controlled **per test file** by a constant at the top:

```swift
private let isRecording = false  // Set to true to record new snapshots
```

That constant is passed as `record: isRecording` into `assertSnapshot`. Repo conventions:
`precision: 0.99`, device layouts such as `.device(config: .iPhone13)` / `.iPadPro12_9` /
`.fixed(width:height:)`, and light/dark via `@Test(arguments:)` plus
`.environment(\.colorScheme, _)`. Match these when adding assertions. (`SnapshotTestHelper` in
VERACoreSnapshotTests is dead code with zero call sites — real tests call `assertSnapshot`
directly.)

## Step 0: Rule out a fake failure

Before recording anything, check whether the *references* are the problem. `.lfsconfig` sets
`skipSmudge = true`, so on a fresh clone every `__Snapshots__/*.png` is a text pointer and all
snapshot tests fail with nonsense diffs:

```bash
head -c 100 "$(find VERA -path '*__Snapshots__*' -name '*.png' | head -1)"
```

If that prints `version https://git-lfs...`, run `git lfs pull` and re-run the tests. **Do not
record over pointer files.** A failure in only some variants after a real UI change is
legitimate — proceed.

## Step 1: Flip record mode

Set `isRecording = true` in **only** the failing test file(s), never repo-wide. Snapshots live
next to the test file: `.../<TestDir>/__Snapshots__/<SuiteName>/<testName>.<named>.png`.

## Step 2: Run the suite (recording)

Simulator is always **iPhone 17** (no OS pin), and snapshot runs must be non-parallel for
rendering determinism:

```bash
xcodebuild test \
  -workspace VERA/VERA.xcworkspace \
  -scheme <Module>SnapshotTests \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -parallel-testing-enabled NO \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO | xcpretty
```

To touch one suite only, add `-only-testing:<Module>SnapshotTests/<SuiteTypeName>` — the Swift
type name, not the `@Suite("...")` display string. A recording run **fails by design**; that is
success for this step, the PNGs were written.

## Step 3: Flip back and verify

1. Set `isRecording = false` again. **Never leave `record: true` behind** — SwiftLint excludes
   snapshot directories and the pre-push hook only checks formatting, so nothing automated
   catches it. Grep before finishing:
   ```bash
   grep -rn "isRecording = true\|record: true" VERA --include="*.swift" | grep -i snapshot
   ```
2. Re-run the same command; everything must pass green.
3. Inspect the diff (`git status`, `git diff --stat` on `__Snapshots__`) and **open the changed
   PNGs** to confirm they show the intended change and nothing drifted. Unexpectedly changed
   files are a side effect worth flagging, not committing.
4. The PNGs belong in the same change as the code; they are LFS-tracked via `.gitattributes`.

## Notes

- CI runs all snapshot targets through the aggregate `VERASnapshotTests-iOS` scheme with the
  same destination and `-parallel-testing-enabled NO`, so local green predicts CI.
- When a design-token change invalidates many modules, re-record module by module. Per-file
  flags keep the blast radius reviewable; a global env-var switch is not the repo convention.
