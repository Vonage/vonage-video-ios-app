---
status: developed
verification: maestro
parity_rows:
  - Participant List
  - Participant Counter
  - Participant Search
  - Pin participants
  - Grid View
maestro_flows:
  - force-mute-from-participants-list.yaml
---

# Participants and layout

## Sub-features

- Participant list with the count of people in the call.
- Search in the participant list.
- Grid view of participant tiles.
- Pin a participant.

## How to get to it (user POV)

1. Join a call (see Room entry and lifecycle).
2. Tap the participants button in the bottom bar to open the list.
3. Pinning is done from a participant tile in the grid.

## Driving it with Maestro

```bash
scripts/vera-verify launch --scenario force-mute    # adds "Remote Participant" so the list has two people
scripts/vera-verify drive --feature participants-and-layout
```

Ids: `meeting-room-participants-button`, `participants-list-screen`, `participant-card-<id>`. In the `force-mute` scenario the ids are `e2e-local-publisher` ("Moderator") and `e2e-remote-participant` ("Remote Participant").

Proof today: `force-mute-from-participants-list` opens the list and shows both participants. Search, counter, pin and grid have no dedicated flow; use `hierarchy` to get the ids on screen, drive them in a temporary flow and keep the screenshots.

## Gotchas

- The `default` scenario has only the local user, so the list, search and pin need the `force-mute` scenario or a real second participant.
- Grid layout changes with the number of tiles and the screen size; record which simulator you used.
