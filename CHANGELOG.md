# Changelog

## 0.2.0 — 2026-08-12

### Added

- `GatewayOpcode`/`GatewayCloseCode` — the full opcode (0–16) and close
  code (4000–4012) tables, verified against Fluxer's own source.
- An explicit `GatewayConnectionState` state machine (`Disconnected →
  Connecting → Identifying|Resuming → Connected → Reconnecting →
  Closed`) driving every transition.
- `HeartbeatManager` — jittered heartbeat scheduling and ack tracking,
  matching Fluxer's own jitter formula.
- A sealed `GatewayEvent` hierarchy covering 22 typed dispatch events
  (session lifecycle, message create/update/delete/reactions/typing,
  guild/role/member/ban CRUD, channel CRUD), with an
  `UnknownDispatchEvent` fallback so unrecognized event names don't
  crash the connection.
- `GatewayConnection` — per-shard HELLO → IDENTIFY/RESUME → heartbeat →
  typed dispatch, with backoff-based reconnect and RESUME-when-possible
  handling, behind a `GatewayTransport` interface for testability.
- `GatewayShardManager` — owns one `GatewayConnection` per shard, merges
  their streams, and paces IDENTIFYs across
  `session_start_limit.max_concurrency` buckets.

### Fixed

- `GuildBanAddEvent`/`GuildBanRemoveEvent`/`GuildMemberRemoveEvent`
  assumed their `user` field was a full `User` object, matching the
  reference client's TypeScript type — the real wire payload only ever
  sends `{id}`. All three now carry a plain `Snowflake userId` instead
  of attempting to decode a partial object as a full `User`.

## 0.1.0

Initial scaffolding: `pubspec.yaml`, `analysis_options.yaml`, MIT
license, CI.
