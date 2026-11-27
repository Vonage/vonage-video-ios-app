---
status: developed
verification: maestro
parity_rows:
  - Waiting Room
  - Auto-generate Room Names
  - Rejoin from goodbye screen
maestro_flows:
  - create-new-room.yaml
  - deep-link-plain-room.yaml
  - goodbye-reenter-room.yaml
  - goodbye-view-landing-page.yaml
---

# Room entry and lifecycle

## Sub-features

- Join a named room from the landing screen.
- Create a room with a generated name.
- Open a room from a `vera://` deep link, which skips the landing screen.
- Waiting room before joining.
- Goodbye screen after leaving, with "rejoin" and "back to landing".

## How to get to it (user POV)

1. Landing screen: type a room name and tap Join, or tap "Create a new room".
2. Waiting room: type a name and tap Join meeting.
3. Meeting room: tap the red end-call button to reach the goodbye screen.
4. Goodbye screen: "Go back to meeting" returns to the waiting room; "View landing page" returns home.

## Driving it with Maestro

```bash
scripts/vera-verify drive --feature room-entry-and-lifecycle
scripts/vera-verify deep-link "vera://<host>/room/my-room"   # host = the app's base URL host
```

Ids: `landing-screen`, `room-name-input`, `join-waiting-room-button`, `create-new-room-button`, `waiting-room-screen`, `username-input`, `join-meeting-button`, `meeting-room-screen`, `meeting-room-end-call-button`, `goodbye-screen`, `goodbye-reenter-button`, `goodbye-landing-page-button`.

Proof: `goodbye-reenter-room` captures the meeting room, the goodbye screen, the waiting room again and the meeting room again (`01-*` to `04-*`).

## Gotchas

- A deep link only routes when its host matches the host VERA was built with. `vera-verify drive` passes the right `DEEP_LINK_TEST_URL`; when you call `deep-link` by hand, use that host.
- iOS may show an "Open in VERA?" dialog for deep links; `helpers/dismiss_deeplink_dialog.yaml` handles it.
- `deep-link-session-key.yaml` covers session-key links and also lives here if you need it: run it with `drive --flow`.
