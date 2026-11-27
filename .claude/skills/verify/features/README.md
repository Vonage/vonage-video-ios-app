# VERA iOS Feature Map

What a user can do in VERA iOS, how to reach it, and how to prove it with `scripts/vera-verify`. `parity_rows` lists the feature names used to track parity between Web, iOS and Android.

| Feature | Status | Verification | Parity rows |
|---|---|---|---|
| [Meeting audio and video](meeting-audio-video.md) | developed | maestro | Basic Audio/Video, Mute/Unmute, Speaking detection while muted, Local audio level indicator, Test audio output, Camera Switch (Front/Rear) |
| [Room entry and lifecycle](room-entry-and-lifecycle.md) | developed | maestro | Waiting Room, Auto-generate Room Names, Rejoin from goodbye screen |
| [Participants and layout](participants-and-layout.md) | developed | maestro | Participant List, Participant Counter, Participant Search, Pin participants, Grid View |
| [Moderation: force mute](moderation-force-mute.md) | developed | maestro | Force mute |
| [Recording](recording.md) | developed | maestro | Archiving (Cloud Recording), Recording Indication |

Verification values: `maestro` (a flow in `.maestro/flows` proves it), `manual-simulator` (drive it by hand with screenshot, hierarchy and deep-link), `manual-device` (needs a physical device), `indirect` (only a setting or overlay shows it), `source-only` (no user-visible proof).

Start every journey from the landing screen (`landing-screen`). The shared path into a call is: `room-name-input` → `join-waiting-room-button` → `waiting-room-screen` → `username-input` → `join-meeting-button` → `meeting-room-screen`.
