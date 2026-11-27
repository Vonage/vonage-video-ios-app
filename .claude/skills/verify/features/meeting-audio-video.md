---
status: developed
verification: maestro
parity_rows:
  - Basic Audio/Video
  - Mute/Unmute
  - Speaking detection while muted
  - Local audio level indicator
  - Test audio output
  - Camera Switch (Front/Rear)
maestro_flows:
  - join-with-camera-mic-allowed.yaml
  - waiting-room-controls-enabled.yaml
  - waiting-room-controls-disabled.yaml
  - speaking-while-muted.yaml
---

# Meeting audio and video

## Sub-features

- Join a call with camera and microphone on.
- Turn microphone and camera on or off in the waiting room; the choice carries into the meeting room.
- Mute and unmute during the call.
- "You are speaking while muted" toast when the muted user talks.
- Local audio level indicator next to the microphone control.
- Test audio output and camera switch.

## How to get to it (user POV)

1. On the landing screen, type a room name and tap Join.
2. In the waiting room, use the microphone and camera buttons under the preview, type a name and tap Join meeting.
3. In the meeting room, the microphone and camera buttons sit in the bottom bar.

## Driving it with Maestro

```bash
scripts/vera-verify drive --feature meeting-audio-video
```

Ids: `waiting-room-mic-enabled` / `waiting-room-mic-disabled`, `waiting-room-camera-enabled` / `waiting-room-camera-disabled`, `meeting-room-mic-enabled` / `meeting-room-mic-disabled`, `meeting-room-camera-enabled` / `meeting-room-camera-disabled`. Each id names the current state, so asserting the id proves the state.

Proof: `waiting-room-controls-disabled` shows both controls off in the waiting room (`01-*`) and still off after joining (`02-*`). `speaking-while-muted` shows the toast after muting.

## Gotchas

- The simulator has no real camera, so the preview is a placeholder. Camera switch and real video frames need a physical device.
- `speaking-while-muted` relies on the E2E mock simulating loud audio after mute. The toast lives about 4.5 s and is emitted once, so do not add waits between the mute tap and the toast assertion.
- Test audio output and the audio level indicator have no flow yet; check them by hand with `screenshot` while audio plays.
