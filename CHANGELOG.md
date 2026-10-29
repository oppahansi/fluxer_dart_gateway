# Changelog

## 0.6.0

- Pins `fluxer_dart_core` 0.6.0.

## 0.5.0

- `ChannelUpdateBulkEvent` and `GuildRoleUpdateBulkEvent`. A channel
  reorder carries every channel of the guild in full, and can arrive
  more than once for one reorder; a role reorder or hoist change carries
  only the roles that changed.
- `GuildMembersChunkEvent` and `RateLimitedEvent`, the answer to
  `requestGuildMembers` and its refusal. A full member list may be
  requested once per guild every 30 seconds.
- `UserUpdateEvent`, for this bot's own user record.
- **Breaking for exhaustive switches:** a `switch` over `GatewayEvent`
  without a default has to handle the five new variants.
- `GuildCreateEvent` now carries the guild's `channels`, `emojis`,
  `stickers`, `members` (this bot's own plus voice participants),
  `voiceStates` and `joinedAt`. A member whose `user` arrives as a bare
  id is skipped rather than failing the guild.
- `GuildSyncEvent`, the same state sent again on request.
- `PresenceUpdateEvent` and `PresenceUpdateBulkEvent`.
- `GuildMemberListUpdateEvent` with `MemberListGroup`,
  `MemberListOperation` and the sealed `MemberListItem`, and
  `ThreadMemberListUpdateEvent`.
- `GuildCountsUpdateEvent`, `ChannelMemberCountsUpdateEvent` and
  `ForumUnreadsEvent`, answering the new count and unread commands.
- `VoiceStateUpdateEvent`.
- `GatewayConnection.lazyRequest` with `GuildSubscription`,
  `requestGuildCounts`, `requestChannelMemberCounts` and
  `requestForumUnreads` with `ForumUnreadRequest`.
- Corrected the `requestGuildMembers` documentation: only a full-list
  request is limited to once per 30 seconds per guild.
- `ChannelRecipientAddEvent` and `ChannelRecipientRemoveEvent`.
- `MessageReactionAddManyEvent`, the batched DM reactions a session
  identified with `SessionFlag.debounceMessageReactions` receives. The
  flag was already exposed, so such a session got them untyped.
- Pins `fluxer_dart_core` 0.5.0.

## 0.4.0

- Six thread events: `ThreadCreateEvent`, `ThreadUpdateEvent`,
  `ThreadDeleteEvent`, `ThreadListSyncEvent`, `ThreadMemberUpdateEvent`
  and `ThreadMembersUpdateEvent`. They previously arrived as
  `UnknownDispatchEvent`. Create and update carry the whole thread, not a
  partial.
- **Breaking for exhaustive switches:** a `switch` over `GatewayEvent`
  without a default now has to handle the six new variants.
- `GuildCreateEvent.threads` lists the guild's active threads the session
  can view. `GuildCreateEvent` gained a `fromJson` factory to decode it.
- `SessionFlag.channelThreads`. A bot session receives threads without
  it; it is there for user sessions.
- `GatewayOpcode.requestForumUnreads` (28).
- `THREAD_MEMBER_LIST_UPDATE` and `FORUM_UNREADS` are not modelled. Both
  answer a subscription this package does not send.

## 0.3.0

- No functional change. Re-released to pin `fluxer_dart_core` 0.3.0,
  which carries decoding fixes this package's dispatch decoding depends
  on: a webhook without a token, and a message reference without a
  message id.

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
