# Presence Service – Architecture and Operations

This document explains how presence works in Shopple, why it’s both accurate and cost‑efficient, and what the 90‑second “online grace” is for.

## Goals

- Instant, accurate green-dot presence for users and list members.
- Resilient offline marking even on crash or power loss.
- Low write costs (avoid needless Firestore writes).
- Fallback that still works when Realtime Database (RTDB) isn’t available.

## Data model at a glance

- Realtime Database (RTDB)
  - Path: `/status/{uid}`
  - Shape: `{ state: 'online'|'offline', last_changed: <server ms> }`
  - Purpose: Fast flips and server-side onDisconnect().

- Firestore
  - `status/{uid}` – canonical presence doc with server timestamps and optional fields:
    - `{ state: 'online'|'offline', last_changed: serverTimestamp(), customStatus?, statusEmoji? }`
  - `users/{uid}.presence` – mirror for convenience/co-location with profile:
    - `{ state: 'online'|'offline'|<missing>, last_changed: serverTimestamp() }`

## Lifecycle and flow

1) Initialize (after sign-in):
   - RTDB connection is obtained (optimized if available).
   - We listen to RTDB `.info/connected`.
   - On CONNECT:
     - Set server-side onDisconnect at `/status/{uid}` → `{ state: 'offline', last_changed: ServerValue.timestamp }`.
     - Immediately set RTDB `/status/{uid}` → `{ state: 'online', last_changed: ServerValue.timestamp }`.
     - Mirror “online” once to Firestore: `status/{uid}` and `users/{uid}.presence`.
   - On temporary DISCONNECT events, we don’t spam writes; the server onDisconnect finalizes if the connection truly drops.

2) Rendering presence in UI:
   - Widgets call `PresenceService.getUserPresenceStream(uid)`.
   - The stream merges three sources:
     - RTDB `/status/{uid}` → fastest, instant online/offline.
     - Firestore `status/{uid}` → state, last_seen, customStatus/emoji.
     - Firestore `users/{uid}.presence` → mirror; useful fallback.
   - Merge rules:
     - isOnline is true if RTDB reports online OR Firestore `status/{uid}` reports online.
     - lastSeen is the latest timestamp across sources.
     - If Firestore explicitly says `offline`, we do NOT override with a recent last_seen.
     - For the current user, we optimistically seed `online=true` to avoid initial UI lag.

3) Logout / account switch:
   - `PresenceService.setOffline()` writes `offline` to RTDB and Firestore.
   - `PresenceService.dispose()` cancels listeners and timers.

## The 90‑second “online grace”

Code: `static const Duration _onlineGrace = Duration(seconds: 90);`

- Where it’s used: Only when reading `users/{uid}.presence` mirror and only if the mirror’s `state` is missing/unknown.
- What it does: If `state` is null but `last_changed` is recent (≤ 90s), we infer the user may still be online as a convenience fallback.
- What it does NOT do:
  - It never overrides an explicit Firestore `state: 'offline'`.
  - It’s not used when RTDB or `status/{uid}` already tells us the truth.

Why 90 seconds?
- Network hiccups and delayed writes can make the mirror briefly stale; 90s avoids flicker while remaining conservative.
- It’s only a fallback path; with RTDB enabled, your green dot is driven by RTDB and updates instantly.

If you prefer a different window: change `_onlineGrace` in `PresenceService`, or we can expose it via `PresenceService.configure()` in a future PR.

## Efficiency and cost control

- RTDB for flips; Firestore mirrors minimally:
  - On connect: 1 RTDB write (online) + 1 Firestore write to `status/{uid}` + 1 Firestore write to `users/{uid}.presence`.
  - On true disconnect (server-detected): 1 RTDB onDisconnect write (offline). Firestore offline is written on explicit app logout/switch.

- Heartbeat strategy:
  - When RTDB is available, we configure `disableHeartbeatWhenRtdb: true` to avoid periodic Firestore writes entirely.
  - If RTDB is not available, a lightweight heartbeat (~1 minute) keeps `status/{uid}.last_seen` reasonably fresh.

- Reads are streamed:
  - Listening to RTDB `.onValue` is cheap and immediate.
  - Firestore snapshots are used for metadata (custom status, last_seen) and redundancy.

## Failure modes and resilience

- App crash / process kill / power loss:
  - Server executes onDisconnect and sets RTDB offline.

- Temporary network loss:
  - We don’t spam offline; once the connection truly drops, onDisconnect writes offline.

- RTDB unavailable or misconfigured:
  - Presence falls back to Firestore-only mode with a short heartbeat.

## Configuration knobs

Use `PresenceService.configure(...)` early during app init:

- `disableHeartbeatWhenRtdb: true` → eliminate periodic Firestore writes in RTDB mode.
- `heartbeatWhenFsOnly: Duration(minutes: 1)` → Firestore-only freshness.
- `heartbeatWhenRtdb: Duration(minutes: 10)` → kept for completeness when heartbeats are enabled.
- `debugLogging: true` → per-source and merged presence logs for troubleshooting.

## Security and rules (summary)

- RTDB rules should allow each authenticated user to write only their own `/status/{uid}` and read `status/*` for presence.
- Firestore rules should permit reading `status/{uid}` and `users/{uid}.presence` according to your app’s privacy model.

## Operational tips

- Test with two devices/accounts; watch RTDB logs flip instantly (⚡) and the merged result (🧩).
- Keep RTDB and Firestore regions stable; cross-region works, but co-location can reduce latency.
- If you see frequent “offline/online flicker,” verify onDisconnect setup and ensure the app doesn’t write offline on transient disconnects.

---

For changes or tuning requests (e.g., making the grace window configurable, or adjusting heartbeat behavior), open an issue or ping the maintainers.
