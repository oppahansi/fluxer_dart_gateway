# Changelog

## 0.1.0 — Initial release

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
  crash the connection. `GuildBanAddEvent`/`GuildBanRemoveEvent`/
  `GuildMemberRemoveEvent` carry a plain `Snowflake userId` rather than
  a full `User` — confirmed against the live wire payload, which only
  ever sends `{id}` for that field.
- `GatewayConnection` — per-shard HELLO → IDENTIFY/RESUME → heartbeat →
  typed dispatch, with backoff-based reconnect and RESUME-when-possible
  handling, behind a `GatewayTransport` interface for testability.
- `GatewayShardManager` — owns one `GatewayConnection` per shard, merges
  their streams, and paces IDENTIFYs across
  `session_start_limit.max_concurrency` buckets.
