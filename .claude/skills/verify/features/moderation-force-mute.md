---
status: developed
verification: maestro
parity_rows:
  - Force mute
maestro_flows:
  - force-mute-from-participants-list.yaml
  - force-mute-from-participant-card.yaml
---

# Moderation: force mute

## Sub-features

- Mute another participant from the participant list.
- Mute another participant from their card.
- Confirmation toast after muting.

## How to get to it (user POV)

1. Join a call with at least one other participant who has the microphone on.
2. Open the participant list, or open the participant's card.
3. Tap the mute action next to that participant.

## Driving it with Maestro

```bash
scripts/vera-verify drive --feature moderation-force-mute
```

Both flows launch the app with `VERA_E2E_SCENARIO=force-mute` themselves. Ids: `participant-card-e2e-remote-participant`, `participant-mic-e2e-remote-participant-enabled`, `participant-force-mute-e2e-remote-participant`, `participant-list-force-mute-<id>`.

Proof: the remote participant's microphone shows enabled, the force-mute control is available, and after the tap the toast "Remote Participant was muted." appears.

## Gotchas

- Both flows are marked `# vera-runner: mock-only`, so `drive --online` skips them. Online proof needs a second real participant, for example the Web VERA PR snapshot in another browser.
- The toast text is English. `launch` pins the app to English by default (`--language en`), so run `launch` before `drive` when the simulator is set to another language. Without it the confirmation alert is localized and the text assertion fails.
