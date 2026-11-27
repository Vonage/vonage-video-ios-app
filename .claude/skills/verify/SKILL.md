---
name: verify
description: Drive the real VERA iOS app in the simulator the way a user does and capture proof that a change works — build, launch with E2E mocks or a real backend, run Maestro flows per feature, take screenshots, logs and video, then clean up. Use whenever the user asks to verify, demo, reproduce or prove a behavior in the running app, after a UI or flow change, or to find which accessibility ids are on screen. Feature-by-feature navigation lives in the Feature Map under features/.
inclusion: manual
---

# Verify VERA iOS in the simulator

`scripts/vera-verify` is the only entry point. It wraps `xcodebuild`, `xcrun simctl` and Maestro, prints one JSON object per command on stdout and progress on stderr. Read `ok`, `error` and `next_action` from the JSON instead of parsing stderr. `scripts/vera-verify <command> --help` documents every option.

The Feature Map in `.claude/skills/verify/features/README.md` says how to reach each feature, which flows prove it, and what the simulator cannot do. Open it before driving anything.

## Launch

```bash
scripts/vera-verify doctor                       # read-only, run first
scripts/vera-verify build                        # isolated DerivedData: ~/Library/Developer/Xcode/DerivedData/vera-verify
scripts/vera-verify launch --scenario default    # boot if needed, install, launch with mocks
```

- Mock mode (`VERA_E2E_MOCKS=1`) is the default. It needs no credentials and no backend. Scenarios come from `VERA/VERAE2E/VERAE2E/Domain/Scenarios/`: `default`, `force-mute`, `recording`, `captions`. `--fail-endpoint` and `--fail-status` force an HTTP error, as the `error-dialog-on-500` and `login-dialog-on-401` flows do.
- The build needs the workspace and `VERA/VERAApp/VERA/App/Generated/EnvironmentConstants.swift`. If `doctor` reports either missing, run `cd VERA && ./Scripts/builder.sh` once.
- If `build` fails, `launch` refuses to install the previous app in the same run, so a proof never runs on a stale binary.
- Ready means `launch` returned `ok: true`. Maestro flows relaunch the app themselves with their own launch arguments, so `launch` before `drive` is needed to boot, install and set the language.
- The flows assert English text, so `launch` pins VERA to English (`--language en`, the default) whatever the simulator language is. `--language system` follows the simulator. Cleanup removes the override.

### Online mode against a Web VERA PR snapshot

A PR in `Vonage/vonage-video-react-app` deploys a snapshot to Vonage Cloud Runtime when someone comments exactly `vcr:deploy` on it. That comment triggers a deployment, so ask the user before posting it. The bot then replies with the URL.

```bash
scripts/vera-verify online-url --react-pr <N>            # read-only, finds the bot's URL
scripts/vera-verify build --base-url <url>               # bakes the URL in, restores the local constants after
scripts/vera-verify launch --online
scripts/vera-verify drive --feature <slug> --online      # mock-only flows are skipped
```

## Doctor

`scripts/vera-verify doctor` is read-only. It checks the tools, the workspace, the generated constants, the simulator, the build and the install, and its `next_action` names the fix. Run it first, and again after any failure before retrying. If two agents share one machine, do not drive the same simulator from both: pass a different `--device` to each.

## Drive

```bash
scripts/vera-verify drive --feature moderation-force-mute      # flows declared by the feature file
scripts/vera-verify drive --flow recording.yaml                # one flow from .maestro/flows
scripts/vera-verify hierarchy                                  # accessibility ids on screen right now
scripts/vera-verify deep-link 'vera://<host>/room/<name>'
```

- Select by accessibility id (`id:` in Maestro), never by coordinates or by visible text that is localized. Ids are defined next to the views, for example `WaitingRoomAccessibilityID` and `SettingsAccessibilityID`; `grep -rn 'accessibilityIdentifier' VERA` finds the rest.
- To prove something no flow covers yet, drive it with a temporary flow under the run's artifacts directory, built from `hierarchy` output. If it is worth keeping, propose adding it to `.maestro/flows/` and to the feature file.

## Evidence

Everything goes to `verification-artifacts/<run-id>/`, which is git-ignored. Group the commands of one proof with `VERA_VERIFY_RUN_ID=<name>`.

| Command | Writes |
|---|---|
| `drive` | `maestro/<flow>/` with `maestro.log`, the flow's own `takeScreenshot` images and Maestro debug output; `vera.log` on failure |
| `screenshot --name <step>` | `screenshots/<step>.png` |
| `logs --since 10m` | `logs/vera-<time>.log` |
| `record-video start` / `stop` | `videos/recording-<time>.mp4` |
| `hierarchy` | `hierarchy-<time>.json` |

Proof standard:

- Exercise the real user path: tap the control a user taps. Do not call internal setters or add test-only shortcuts.
- Capture the action and the resulting state, not only the final screen. A flow's numbered screenshots or a video do this.
- Mocks are acceptable only at the boundary VERAE2E already isolates (HTTP and the Vonage session). Say in the report that the proof used mocks.
- Report what the simulator cannot prove. Each feature's `Gotchas` names what needs a physical device.

## Cleanup

```bash
scripts/vera-verify cleanup --dry-run   # shows what it would stop
scripts/vera-verify cleanup
```

Cleanup stops the recording, terminates the app and shuts down the simulator only if this run started them, then removes the run state. It never deletes `verification-artifacts/`. Run it after every attempt, including failed ones.

## Helpers

| Path | Purpose |
|---|---|
| `scripts/vera-verify` | The CLI described above |
| `scripts/vera-verify-test.sh` | Self-check for the CLI that needs no simulator; run it after editing the CLI |
| `scripts/run-maestro-tests.sh` | The full Maestro suite as CI runs it. It deletes the repo's `DerivedData/` before building, so prefer `vera-verify` for single features |

## Maintaining the Feature Map

Every file under `features/` has front matter (`status`, `verification`, `parity_rows`, `maestro_flows`) and exactly four sections: `Sub-features`, `How to get to it (user POV)`, `Driving it with Maestro` and `Gotchas`. `parity_rows` lists the feature names used to track parity between Web, iOS and Android. After changing a feature file or a flow, run `scripts/vera-verify map-check`. When a journey fails because the mocks lack a precondition, record the reason in that feature's `Gotchas`; do not weaken the journey to make it pass.
