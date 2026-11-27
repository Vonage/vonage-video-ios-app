---
status: developed
verification: maestro
parity_rows:
  - Archiving (Cloud Recording)
  - Recording Indication
maestro_flows:
  - recording.yaml
---

# Recording

## Sub-features

- Start and stop a cloud recording from the meeting room.
- Recording indicator while the recording runs.

## How to get to it (user POV)

1. Join a call.
2. Tap the start recording button. On smaller screens it is in the "more options" menu.
3. Confirm the alert. The recording indicator appears.

## Driving it with Maestro

```bash
scripts/vera-verify drive --feature recording
```

The flow launches with `VERA_E2E_SCENARIO=recording`. Ids: `meeting-room-more-options-button`, `archiving-start-recording-button`, `archiving-recording-indicator`, `archiving-stop-recording-button`.

Proof: `02-recording-in-progress` shows the indicator after the confirmation and `03-recording-stopped` shows it gone after stopping.

## Gotchas

- Requires `meetingRoomSettings.allowArchiving` in `VERA/Config/app-config.json`; without it the module is not compiled (`ARCHIVING_ENABLED`).
- Recording consent notice is not implemented on iOS yet, so there is no consent dialog to expect.
- With mocks no real archive is produced. An online run against a real backend is needed to prove the archive exists.
