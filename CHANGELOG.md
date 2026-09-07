# Changelog

## 0.2.0

- **Fixed:** a dispatch whose payload is not a JSON object no longer
  throws out of the message handler and take the connection down with it.
  `SESSIONS_REPLACE` sends a bare array, which crashed any bot whose
  account had a second live session.
- **Breaking:** `GatewayEvent.fromDispatch` takes `Object?` rather than
  `Map<String, dynamic>`, and `UnknownDispatchEvent.data` is `Object?`,
  because a dispatch payload is not guaranteed to be an object.
- **Fixed:** `GatewayCloseCode.isRecoverable` now also reports
  `notAuthenticated`, `invalidShard` and `shardingRequired` as terminal.
  Reconnecting after those reproduces the same close. Added `canResume`,
  which additionally excludes `invalidSeq` and `sessionTimeout`.
- Ten new typed events: `MessageDeleteBulkEvent`,
  `MessageReactionRemoveAllEvent`, `MessageReactionRemoveEmojiEvent`,
  `ChannelPinsUpdateEvent`, `GuildEmojisUpdateEvent`,
  `GuildStickersUpdateEvent`, `GuildAuditLogEntryCreateEvent`,
  `WebhooksUpdateEvent`, `InviteCreateEvent`, `InviteDeleteEvent`, plus
  `SessionsReplaceEvent`.
- IDENTIFY gained `ignoredEvents`, `initialPresence`, `initialGuildId`
  and `sessionFlags`. Fluxer has no intent bitfield; `ignoredEvents` is
  how a session limits its traffic.
- `SessionFlag` / `SessionFlags` for the IDENTIFY flags bitfield.
- New client commands: `GatewayConnection.updatePresence` (opcode 3) and
  `requestGuildMembers` (opcode 8).

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
