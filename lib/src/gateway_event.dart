import 'package:fluxer_dart_core/fluxer_dart_core.dart';

/// A decoded DISPATCH (opcode 0) payload.
///
/// Sealed, so a `switch` over an event value is checked for
/// exhaustiveness at compile time. Covers session lifecycle plus the
/// message, reaction, pin, channel, thread, role, member, ban, emoji,
/// sticker, invite, webhook and audit-log events a moderation or utility
/// bot acts on. Every other dispatch name decodes to [UnknownDispatchEvent],
/// carrying its raw payload, rather than being dropped.
///
/// Several update and remove events carry a **partial** payload rather
/// than a full resource, and the partial form is not always narrower in
/// the way the same-named REST response would suggest:
///
/// - [MessageUpdateEvent] and [ChannelUpdateEvent] carry only the fields
///   that changed.
/// - [GuildMemberRemoveEvent], [GuildBanAddEvent] and
///   [GuildBanRemoveEvent] carry a `user` object holding nothing but
///   `id`, so they expose a [Snowflake] instead of a decoded [User].
/// - [MessageDeleteBulkEvent] names its id list `ids`, not the
///   `message_ids` its REST counterpart accepts.
/// - [ChannelPinsUpdateEvent] and [WebhooksUpdateEvent] carry no
///   resource data at all; acting on them requires a REST fetch.
///
/// The bulk events are the opposite: [ChannelUpdateBulkEvent] carries
/// every channel of the guild in full, and [GuildRoleUpdateBulkEvent]
/// every changed role in full.
sealed class GatewayEvent {
  const GatewayEvent();

  /// Decodes a raw `{t: eventName, d: payload}` DISPATCH body into a
  /// typed event, or [UnknownDispatchEvent] if [eventName] is not
  /// modelled.
  ///
  /// [data] is typed as `Object?` because a dispatch payload is not
  /// always a JSON object: `SESSIONS_REPLACE` sends a bare array, and an
  /// unmodelled event may send anything. Events whose payload must be an
  /// object are decoded only after that is checked.
  factory GatewayEvent.fromDispatch(String eventName, Object? payload) {
    if (eventName == 'SESSIONS_REPLACE') {
      return SessionsReplaceEvent.fromJson(payload);
    }
    if (payload is! Map) {
      return UnknownDispatchEvent(eventName, payload);
    }
    // Widened rather than cast directly: a payload decoded from JSON is
    // always Map<String, dynamic>, but one built in a test or forwarded
    // from another decoder may carry a narrower value type.
    final data = payload.cast<String, dynamic>();
    return switch (eventName) {
      'READY' => ReadyEvent.fromJson(data),
      'RESUMED' => const ResumedEvent(),
      'MESSAGE_CREATE' => MessageCreateEvent(Message.fromJson(data)),
      'MESSAGE_UPDATE' => MessageUpdateEvent.fromJson(data),
      'MESSAGE_DELETE' => MessageDeleteEvent.fromJson(data),
      'MESSAGE_REACTION_ADD' => MessageReactionAddEvent.fromJson(data),
      'MESSAGE_REACTION_REMOVE' => MessageReactionRemoveEvent.fromJson(data),
      'MESSAGE_DELETE_BULK' => MessageDeleteBulkEvent.fromJson(data),
      'MESSAGE_REACTION_REMOVE_ALL' => MessageReactionRemoveAllEvent.fromJson(
        data,
      ),
      'MESSAGE_REACTION_REMOVE_EMOJI' =>
        MessageReactionRemoveEmojiEvent.fromJson(data),
      'CHANNEL_PINS_UPDATE' => ChannelPinsUpdateEvent.fromJson(data),
      'TYPING_START' => TypingStartEvent.fromJson(data),
      'GUILD_CREATE' => GuildCreateEvent.fromJson(data),
      'GUILD_UPDATE' => GuildUpdateEvent(Guild.fromJson(data)),
      'GUILD_DELETE' => GuildDeleteEvent.fromJson(data),
      'GUILD_ROLE_CREATE' => GuildRoleCreateEvent.fromJson(data),
      'GUILD_ROLE_UPDATE' => GuildRoleUpdateEvent.fromJson(data),
      'GUILD_ROLE_DELETE' => GuildRoleDeleteEvent.fromJson(data),
      'GUILD_ROLE_UPDATE_BULK' => GuildRoleUpdateBulkEvent.fromJson(data),
      'GUILD_MEMBERS_CHUNK' => GuildMembersChunkEvent.fromJson(data),
      'RATE_LIMITED' => RateLimitedEvent.fromJson(data),
      'USER_UPDATE' => UserUpdateEvent(User.fromJson(data)),
      'GUILD_MEMBER_ADD' => GuildMemberAddEvent.fromJson(data),
      'GUILD_MEMBER_UPDATE' => GuildMemberUpdateEvent.fromJson(data),
      'GUILD_MEMBER_REMOVE' => GuildMemberRemoveEvent.fromJson(data),
      'GUILD_BAN_ADD' => GuildBanAddEvent.fromJson(data),
      'GUILD_BAN_REMOVE' => GuildBanRemoveEvent.fromJson(data),
      'CHANNEL_CREATE' => ChannelCreateEvent(Channel.fromJson(data)),
      'CHANNEL_UPDATE' => ChannelUpdateEvent.fromJson(data),
      'CHANNEL_DELETE' => ChannelDeleteEvent.fromJson(data),
      'CHANNEL_UPDATE_BULK' => ChannelUpdateBulkEvent.fromJson(data),
      'GUILD_EMOJIS_UPDATE' => GuildEmojisUpdateEvent.fromJson(data),
      'GUILD_STICKERS_UPDATE' => GuildStickersUpdateEvent.fromJson(data),
      'GUILD_AUDIT_LOG_ENTRY_CREATE' => GuildAuditLogEntryCreateEvent.fromJson(
        data,
      ),
      'WEBHOOKS_UPDATE' => WebhooksUpdateEvent.fromJson(data),
      'INVITE_CREATE' => InviteCreateEvent.fromJson(data),
      'INVITE_DELETE' => InviteDeleteEvent.fromJson(data),
      'THREAD_CREATE' => ThreadCreateEvent.fromJson(data),
      'THREAD_UPDATE' => ThreadUpdateEvent(ThreadChannel.fromJson(data)),
      'THREAD_DELETE' => ThreadDeleteEvent.fromJson(data),
      'THREAD_LIST_SYNC' => ThreadListSyncEvent.fromJson(data),
      'THREAD_MEMBER_UPDATE' => ThreadMemberUpdateEvent.fromJson(data),
      'THREAD_MEMBERS_UPDATE' => ThreadMembersUpdateEvent.fromJson(data),
      _ => UnknownDispatchEvent(eventName, data),
    };
  }
}

/// The first event on a new session, confirming IDENTIFY succeeded.
final class ReadyEvent extends GatewayEvent {
  const ReadyEvent({required this.sessionId, required this.user});

  factory ReadyEvent.fromJson(Map<String, dynamic> json) => ReadyEvent(
    sessionId: json['session_id'] as String,
    user: User.fromJson(json['user'] as Map<String, dynamic>),
  );

  /// The session ID to use for RESUME if this connection later drops.
  final String sessionId;

  final User user;

  @override
  String toString() =>
      'ReadyEvent(session: $sessionId, user: ${user.username})';
}

/// Confirms a RESUME succeeded and the session picked back up where it
/// left off.
final class ResumedEvent extends GatewayEvent {
  const ResumedEvent();

  @override
  String toString() => 'ResumedEvent';
}

final class MessageCreateEvent extends GatewayEvent {
  const MessageCreateEvent(this.message);

  final Message message;

  @override
  String toString() => 'MessageCreateEvent($message)';
}

final class GuildCreateEvent extends GatewayEvent {
  const GuildCreateEvent(this.guild, {this.threads = const []});

  factory GuildCreateEvent.fromJson(Map<String, dynamic> json) =>
      GuildCreateEvent(
        Guild.fromGuildCreateJson(json),
        threads: (json['threads'] as List<dynamic>? ?? const [])
            .map((t) => ThreadChannel.fromJson(t as Map<String, dynamic>))
            .toList(growable: false),
      );

  final Guild guild;

  /// The guild's active threads this session can view. A thread the
  /// session has joined carries its [ThreadChannel.member], without the
  /// thread and user ids that object has elsewhere.
  final List<ThreadChannel> threads;

  @override
  String toString() => 'GuildCreateEvent($guild)';
}

// --- Message events ---------------------------------------------------

/// A message was edited. Carries only [messageId]/[channelId] plus the
/// raw [data] — see the class-level note on why this doesn't reuse
/// `Message.fromJson`: verified against `MessageUpdate.ts`, the payload
/// is `{id, channel_id?, ...whatever changed}`, not a guaranteed-full
/// message.
final class MessageUpdateEvent extends GatewayEvent {
  const MessageUpdateEvent({
    required this.messageId,
    required this.channelId,
    required this.data,
  });

  factory MessageUpdateEvent.fromJson(Map<String, dynamic> json) =>
      MessageUpdateEvent(
        messageId: Snowflake.parse(json['id'] as String),
        channelId: (json['channel_id'] as String?)?.let(Snowflake.parse),
        data: json,
      );

  final Snowflake messageId;

  /// `null` in the rare case the payload omits it — verified as
  /// genuinely optional in `MessageUpdatePayload`.
  final Snowflake? channelId;
  final Map<String, dynamic> data;

  @override
  String toString() => 'MessageUpdateEvent($messageId)';
}

final class MessageDeleteEvent extends GatewayEvent {
  const MessageDeleteEvent({required this.messageId, required this.channelId});

  factory MessageDeleteEvent.fromJson(Map<String, dynamic> json) =>
      MessageDeleteEvent(
        messageId: Snowflake.parse(json['id'] as String),
        channelId: Snowflake.parse(json['channel_id'] as String),
      );

  final Snowflake messageId;
  final Snowflake channelId;

  @override
  String toString() => 'MessageDeleteEvent($messageId)';
}

final class MessageReactionAddEvent extends GatewayEvent {
  const MessageReactionAddEvent({
    required this.userId,
    required this.channelId,
    required this.messageId,
    required this.emoji,
    required this.guildId,
  });

  factory MessageReactionAddEvent.fromJson(Map<String, dynamic> json) =>
      MessageReactionAddEvent(
        userId: Snowflake.parse(json['user_id'] as String),
        channelId: Snowflake.parse(json['channel_id'] as String),
        messageId: Snowflake.parse(json['message_id'] as String),
        emoji: ReactionEmoji.fromJson(json['emoji'] as Map<String, dynamic>),
        guildId: (json['guild_id'] as String?)?.let(Snowflake.parse),
      );

  final Snowflake userId;
  final Snowflake channelId;
  final Snowflake messageId;
  final ReactionEmoji emoji;

  /// `null` for reactions in a DM.
  final Snowflake? guildId;

  @override
  String toString() => 'MessageReactionAddEvent($messageId, $emoji)';
}

final class MessageReactionRemoveEvent extends GatewayEvent {
  const MessageReactionRemoveEvent({
    required this.userId,
    required this.channelId,
    required this.messageId,
    required this.emoji,
    required this.guildId,
  });

  factory MessageReactionRemoveEvent.fromJson(Map<String, dynamic> json) =>
      MessageReactionRemoveEvent(
        userId: Snowflake.parse(json['user_id'] as String),
        channelId: Snowflake.parse(json['channel_id'] as String),
        messageId: Snowflake.parse(json['message_id'] as String),
        emoji: ReactionEmoji.fromJson(json['emoji'] as Map<String, dynamic>),
        guildId: (json['guild_id'] as String?)?.let(Snowflake.parse),
      );

  final Snowflake userId;
  final Snowflake channelId;
  final Snowflake messageId;
  final ReactionEmoji emoji;
  final Snowflake? guildId;

  @override
  String toString() => 'MessageReactionRemoveEvent($messageId, $emoji)';
}

final class TypingStartEvent extends GatewayEvent {
  const TypingStartEvent({
    required this.channelId,
    required this.userId,
    required this.timestamp,
    required this.guildId,
  });

  factory TypingStartEvent.fromJson(Map<String, dynamic> json) =>
      TypingStartEvent(
        channelId: Snowflake.parse(json['channel_id'] as String),
        userId: Snowflake.parse(json['user_id'] as String),
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          (json['timestamp'] as int) * 1000,
          isUtc: true,
        ),
        guildId: (json['guild_id'] as String?)?.let(Snowflake.parse),
      );

  final Snowflake channelId;
  final Snowflake userId;
  final DateTime timestamp;
  final Snowflake? guildId;

  @override
  String toString() => 'TypingStartEvent($userId in $channelId)';
}

// --- Guild events -------------------------------------------------------

/// Verified flat against `GuildUpdate.ts` (`data: Guild`, the plain REST
/// shape) — unlike [GuildCreateEvent], this one is safe to decode with
/// the ordinary `Guild.fromJson`, not `fromGuildCreateJson`.
final class GuildUpdateEvent extends GatewayEvent {
  const GuildUpdateEvent(this.guild);

  final Guild guild;

  @override
  String toString() => 'GuildUpdateEvent($guild)';
}

/// The bot left/was removed from a guild, or the guild became
/// unavailable (e.g. an outage). Verified against `GuildDelete.ts`'s
/// minimal `{id, unavailable?, unavailable_hidden?}` payload — no guild
/// data beyond identity is actually sent.
final class GuildDeleteEvent extends GatewayEvent {
  const GuildDeleteEvent({required this.guildId, required this.unavailable});

  factory GuildDeleteEvent.fromJson(Map<String, dynamic> json) =>
      GuildDeleteEvent(
        guildId: Snowflake.parse(json['id'] as String),
        unavailable: json['unavailable'] as bool?,
      );

  final Snowflake guildId;

  /// `true` if this is an outage (guild still exists, temporarily
  /// unreachable) rather than the bot actually being removed.
  final bool? unavailable;

  @override
  String toString() => 'GuildDeleteEvent($guildId, unavailable: $unavailable)';
}

final class GuildRoleCreateEvent extends GatewayEvent {
  const GuildRoleCreateEvent({required this.guildId, required this.role});

  factory GuildRoleCreateEvent.fromJson(Map<String, dynamic> json) =>
      GuildRoleCreateEvent(
        guildId: Snowflake.parse(json['guild_id'] as String),
        role: GuildRole.fromJson(json['role'] as Map<String, dynamic>),
      );

  final Snowflake guildId;
  final GuildRole role;

  @override
  String toString() => 'GuildRoleCreateEvent($guildId, ${role.name})';
}

final class GuildRoleUpdateEvent extends GatewayEvent {
  const GuildRoleUpdateEvent({required this.guildId, required this.role});

  factory GuildRoleUpdateEvent.fromJson(Map<String, dynamic> json) =>
      GuildRoleUpdateEvent(
        guildId: Snowflake.parse(json['guild_id'] as String),
        role: GuildRole.fromJson(json['role'] as Map<String, dynamic>),
      );

  final Snowflake guildId;
  final GuildRole role;

  @override
  String toString() => 'GuildRoleUpdateEvent($guildId, ${role.name})';
}

final class GuildRoleDeleteEvent extends GatewayEvent {
  const GuildRoleDeleteEvent({required this.guildId, required this.roleId});

  factory GuildRoleDeleteEvent.fromJson(Map<String, dynamic> json) =>
      GuildRoleDeleteEvent(
        guildId: Snowflake.parse(json['guild_id'] as String),
        roleId: Snowflake.parse(json['role_id'] as String),
      );

  final Snowflake guildId;
  final Snowflake roleId;

  @override
  String toString() => 'GuildRoleDeleteEvent($guildId, $roleId)';
}

/// Verified against `GuildMemberAdd.ts`: the payload is
/// `GuildMemberData & {guild_id}` — i.e. flat `GuildMemberResponse`
/// fields plus `guild_id`, safe to decode with `GuildMember.fromJson`
/// directly since `guild_id` is simply an extra key that factory ignores.
/// One operation changed several roles together: a reorder, or a change
/// to hoist positions.
final class GuildRoleUpdateBulkEvent extends GatewayEvent {
  const GuildRoleUpdateBulkEvent({required this.guildId, required this.roles});

  factory GuildRoleUpdateBulkEvent.fromJson(Map<String, dynamic> json) =>
      GuildRoleUpdateBulkEvent(
        guildId: Snowflake.parse(json['guild_id'] as String),
        roles: (json['roles'] as List<dynamic>)
            .map((r) => GuildRole.fromJson(r as Map<String, dynamic>))
            .toList(growable: false),
      );

  final Snowflake guildId;

  /// Every changed role, in full.
  final List<GuildRole> roles;

  @override
  String toString() => 'GuildRoleUpdateBulkEvent($guildId, ${roles.length})';
}

/// One page of the answer to a Request Guild Members command.
///
/// A request always produces at least one chunk: one that matched nobody
/// has an empty [members], [chunkIndex] 0 and [chunkCount] 1. Never
/// replayed on RESUME.
final class GuildMembersChunkEvent extends GatewayEvent {
  const GuildMembersChunkEvent({
    required this.guildId,
    required this.members,
    required this.chunkIndex,
    required this.chunkCount,
    this.presences = const [],
    this.nonce,
  });

  factory GuildMembersChunkEvent.fromJson(Map<String, dynamic> json) =>
      GuildMembersChunkEvent(
        guildId: Snowflake.parse(json['guild_id'] as String),
        members: (json['members'] as List<dynamic>)
            .map((m) => GuildMember.fromJson(m as Map<String, dynamic>))
            .toList(growable: false),
        chunkIndex: json['chunk_index'] as int,
        chunkCount: json['chunk_count'] as int,
        presences: (json['presences'] as List<dynamic>? ?? const [])
            .map((p) => UserPresence.fromJson(p as Map<String, dynamic>))
            .toList(growable: false),
        nonce: json['nonce'] as String?,
      );

  final Snowflake guildId;

  /// Up to 1,000 members.
  final List<GuildMember> members;

  final int chunkIndex;
  final int chunkCount;

  /// Empty unless the request asked for presences; offline and invisible
  /// members are omitted even then.
  final List<UserPresence> presences;

  /// The request's nonce, echoed only when the request named a single
  /// guild.
  final String? nonce;

  @override
  String toString() =>
      'GuildMembersChunkEvent($guildId, ${chunkIndex + 1}/$chunkCount, ${members.length} members)';
}

/// The gateway refused a command for exceeding its budget.
///
/// Sent only for Request Guild Members (opcode 8), whose full-list form
/// is limited to one request per guild every 30 seconds.
final class RateLimitedEvent extends GatewayEvent {
  const RateLimitedEvent({
    required this.opcode,
    required this.retryAfter,
    required this.guildId,
    this.nonce,
  });

  factory RateLimitedEvent.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return RateLimitedEvent(
      opcode: json['opcode'] as int,
      retryAfter: Duration(
        microseconds: ((json['retry_after'] as num) * 1000000).round(),
      ),
      guildId: (meta['guild_id'] as String?)?.let(Snowflake.parse),
      nonce: meta['nonce'] as String?,
    );
  }

  final int opcode;
  final Duration retryAfter;

  /// The guild the refused request named.
  final Snowflake? guildId;

  /// The refused request's nonce, when it named a single guild.
  final String? nonce;

  @override
  String toString() => 'RateLimitedEvent(op $opcode, retry after $retryAfter)';
}

/// This bot's own user record changed.
final class UserUpdateEvent extends GatewayEvent {
  const UserUpdateEvent(this.user);

  final User user;

  @override
  String toString() => 'UserUpdateEvent(${user.id})';
}

final class GuildMemberAddEvent extends GatewayEvent {
  const GuildMemberAddEvent({required this.guildId, required this.member});

  factory GuildMemberAddEvent.fromJson(Map<String, dynamic> json) =>
      GuildMemberAddEvent(
        guildId: Snowflake.parse(json['guild_id'] as String),
        member: GuildMember.fromJson(json),
      );

  final Snowflake guildId;
  final GuildMember member;

  @override
  String toString() => 'GuildMemberAddEvent($guildId, ${member.displayName})';
}

final class GuildMemberUpdateEvent extends GatewayEvent {
  const GuildMemberUpdateEvent({required this.guildId, required this.member});

  factory GuildMemberUpdateEvent.fromJson(Map<String, dynamic> json) =>
      GuildMemberUpdateEvent(
        guildId: Snowflake.parse(json['guild_id'] as String),
        member: GuildMember.fromJson(json),
      );

  final Snowflake guildId;
  final GuildMember member;

  @override
  String toString() =>
      'GuildMemberUpdateEvent($guildId, ${member.displayName})';
}

/// The `user` sub-object here carries only `{id}` — confirmed live
/// against a real instance, not just assumed from `GuildMemberRemove.ts`
/// (whose TS type claims a fuller `User` shape that doesn't actually
/// show up on the wire, the same gap M3's live regression check was
/// meant to catch and evidently didn't for this one). Carries [userId]
/// rather than a decoded [User] so a genuinely-missing `username` can't
/// throw a cast error.
final class GuildMemberRemoveEvent extends GatewayEvent {
  const GuildMemberRemoveEvent({required this.guildId, required this.userId});

  factory GuildMemberRemoveEvent.fromJson(Map<String, dynamic> json) =>
      GuildMemberRemoveEvent(
        guildId: Snowflake.parse(json['guild_id'] as String),
        userId: Snowflake.parse(
          (json['user'] as Map<String, dynamic>)['id'] as String,
        ),
      );

  final Snowflake guildId;
  final Snowflake userId;

  @override
  String toString() => 'GuildMemberRemoveEvent($guildId, $userId)';
}

/// Same correction as [GuildMemberRemoveEvent]: the `user` sub-object is
/// `{id}` only on the wire, confirmed live, despite `GuildBan.ts`'s
/// fuller-looking TS type.
final class GuildBanAddEvent extends GatewayEvent {
  const GuildBanAddEvent({required this.guildId, required this.userId});

  factory GuildBanAddEvent.fromJson(Map<String, dynamic> json) =>
      GuildBanAddEvent(
        guildId: Snowflake.parse(json['guild_id'] as String),
        userId: Snowflake.parse(
          (json['user'] as Map<String, dynamic>)['id'] as String,
        ),
      );

  final Snowflake guildId;
  final Snowflake userId;

  @override
  String toString() => 'GuildBanAddEvent($guildId, $userId)';
}

final class GuildBanRemoveEvent extends GatewayEvent {
  const GuildBanRemoveEvent({required this.guildId, required this.userId});

  factory GuildBanRemoveEvent.fromJson(Map<String, dynamic> json) =>
      GuildBanRemoveEvent(
        guildId: Snowflake.parse(json['guild_id'] as String),
        userId: Snowflake.parse(
          (json['user'] as Map<String, dynamic>)['id'] as String,
        ),
      );

  final Snowflake guildId;
  final Snowflake userId;

  @override
  String toString() => 'GuildBanRemoveEvent($guildId, $userId)';
}

// --- Channel events -------------------------------------------------------

/// Verified against `ChannelCreate.ts` (`data: Channel`, a full channel)
/// — safe to decode with the ordinary `Channel.fromJson`.
final class ChannelCreateEvent extends GatewayEvent {
  const ChannelCreateEvent(this.channel);

  final Channel channel;

  @override
  String toString() => 'ChannelCreateEvent($channel)';
}

/// Verified against `ChannelUpdate.ts`: the payload type is literally
/// `Partial<Channel> & {id, type}` — only [channelId] and [channelType]
/// are guaranteed, so this carries the raw [data] instead of a decoded
/// `Channel` (see the class-level note on why).
final class ChannelUpdateEvent extends GatewayEvent {
  const ChannelUpdateEvent({
    required this.channelId,
    required this.channelType,
    required this.data,
  });

  factory ChannelUpdateEvent.fromJson(Map<String, dynamic> json) =>
      ChannelUpdateEvent(
        channelId: Snowflake.parse(json['id'] as String),
        channelType: ChannelType.tryFromValue(json['type'] as int),
        data: json,
      );

  final Snowflake channelId;
  final ChannelType? channelType;
  final Map<String, dynamic> data;

  @override
  String toString() => 'ChannelUpdateEvent($channelId)';
}

/// Verified against `ChannelDelete.ts`: `{id, type, guild_id?}` only —
/// despite the reference client's `as Channel` cast, the actual payload
/// carries no other channel data.
final class ChannelDeleteEvent extends GatewayEvent {
  const ChannelDeleteEvent({
    required this.channelId,
    required this.channelType,
    required this.guildId,
  });

  factory ChannelDeleteEvent.fromJson(Map<String, dynamic> json) =>
      ChannelDeleteEvent(
        channelId: Snowflake.parse(json['id'] as String),
        channelType: ChannelType.tryFromValue(json['type'] as int),
        guildId: (json['guild_id'] as String?)?.let(Snowflake.parse),
      );

  final Snowflake channelId;
  final ChannelType? channelType;

  /// `null` for a DM/group DM channel.
  final Snowflake? guildId;

  @override
  String toString() => 'ChannelDeleteEvent($channelId)';
}

// --- Thread events --------------------------------------------------------

/// One operation changed several channels together, most often a
/// reorder.
///
/// [channels] holds every channel of the guild the session can view, in
/// full, not only the ones that moved. A single reorder can send this
/// more than once; the last one carries the final positions.
final class ChannelUpdateBulkEvent extends GatewayEvent {
  const ChannelUpdateBulkEvent({required this.guildId, required this.channels});

  factory ChannelUpdateBulkEvent.fromJson(Map<String, dynamic> json) =>
      ChannelUpdateBulkEvent(
        guildId: Snowflake.parse(json['guild_id'] as String),
        channels: (json['channels'] as List<dynamic>)
            .map((c) => Channel.fromJson(c as Map<String, dynamic>))
            .toList(growable: false),
      );

  final Snowflake guildId;
  final List<Channel> channels;

  @override
  String toString() =>
      'ChannelUpdateBulkEvent($guildId, ${channels.length} channels)';
}

/// A thread was created, or this session's user was added to one.
///
/// Unlike [ChannelUpdateEvent], thread events carry the whole thread.
final class ThreadCreateEvent extends GatewayEvent {
  const ThreadCreateEvent(this.thread, {this.newlyCreated = false});

  factory ThreadCreateEvent.fromJson(Map<String, dynamic> json) =>
      ThreadCreateEvent(
        ThreadChannel.fromJson(json),
        newlyCreated: json['newly_created'] as bool? ?? false,
      );

  final ThreadChannel thread;

  /// True when the thread was just created. False when the event instead
  /// reports this user joining, or being added to, a thread that already
  /// existed.
  final bool newlyCreated;

  @override
  String toString() =>
      'ThreadCreateEvent($thread, newlyCreated: $newlyCreated)';
}

/// A thread changed: renamed, archived, unarchived, locked, retagged, or
/// given a new slowmode or auto archive duration.
///
/// Sending a message to an archived thread unarchives it and produces
/// one of these; a message to an active thread does not.
final class ThreadUpdateEvent extends GatewayEvent {
  const ThreadUpdateEvent(this.thread);

  final ThreadChannel thread;

  @override
  String toString() => 'ThreadUpdateEvent($thread)';
}

/// A thread was deleted, along with its messages and memberships.
final class ThreadDeleteEvent extends GatewayEvent {
  const ThreadDeleteEvent({
    required this.threadId,
    required this.guildId,
    required this.parentId,
    required this.threadType,
  });

  factory ThreadDeleteEvent.fromJson(Map<String, dynamic> json) =>
      ThreadDeleteEvent(
        threadId: Snowflake.parse(json['id'] as String),
        guildId: Snowflake.parse(json['guild_id'] as String),
        parentId: (json['parent_id'] as String?)?.let(Snowflake.parse),
        threadType: switch (json['type']) {
          final int raw => ChannelType.tryFromValue(raw),
          _ => null,
        },
      );

  final Snowflake threadId;
  final Snowflake guildId;
  final Snowflake? parentId;
  final ChannelType? threadType;

  @override
  String toString() => 'ThreadDeleteEvent($threadId)';
}

/// The session's set of active threads was replaced, for a whole guild
/// or for some of its channels.
///
/// Sent when the guild reloads its thread state and when the session
/// gains view access to channels that have active threads. It is never
/// replayed on RESUME.
final class ThreadListSyncEvent extends GatewayEvent {
  const ThreadListSyncEvent({
    required this.guildId,
    required this.channelIds,
    required this.threads,
    required this.members,
  });

  factory ThreadListSyncEvent.fromJson(Map<String, dynamic> json) =>
      ThreadListSyncEvent(
        guildId: Snowflake.parse(json['guild_id'] as String),
        channelIds: (json['channel_ids'] as List<dynamic>?)
            ?.map((c) => Snowflake.parse(c as String))
            .toList(growable: false),
        threads: (json['threads'] as List<dynamic>? ?? const [])
            .map((t) => ThreadChannel.fromJson(t as Map<String, dynamic>))
            .toList(growable: false),
        members: (json['members'] as List<dynamic>? ?? const [])
            .map((m) => ThreadMember.fromJson(m as Map<String, dynamic>))
            .toList(growable: false),
      );

  final Snowflake guildId;

  /// The parent channels whose threads [threads] replaces, or `null`
  /// when it replaces every thread in the guild.
  final List<Snowflake>? channelIds;

  final List<ThreadChannel> threads;

  /// This session's memberships in [threads].
  final List<ThreadMember> members;

  @override
  String toString() =>
      'ThreadListSyncEvent(guild: $guildId, ${threads.length} threads)';
}

/// This session's own membership in a thread changed.
final class ThreadMemberUpdateEvent extends GatewayEvent {
  const ThreadMemberUpdateEvent({required this.guildId, required this.member});

  factory ThreadMemberUpdateEvent.fromJson(Map<String, dynamic> json) =>
      ThreadMemberUpdateEvent(
        guildId: Snowflake.parse(json['guild_id'] as String),
        member: ThreadMember.fromJson(json),
      );

  final Snowflake guildId;
  final ThreadMember member;

  @override
  String toString() => 'ThreadMemberUpdateEvent($member)';
}

/// Users joined or left a thread.
///
/// Each [addedMembers] entry carries the user's guild member, which the
/// same object in a REST response only has on request. A removal is
/// reported by id alone.
final class ThreadMembersUpdateEvent extends GatewayEvent {
  const ThreadMembersUpdateEvent({
    required this.threadId,
    required this.guildId,
    required this.memberCount,
    required this.addedMembers,
    required this.removedMemberIds,
  });

  factory ThreadMembersUpdateEvent.fromJson(Map<String, dynamic> json) =>
      ThreadMembersUpdateEvent(
        threadId: Snowflake.parse(json['id'] as String),
        guildId: Snowflake.parse(json['guild_id'] as String),
        memberCount: json['member_count'] as int? ?? 0,
        addedMembers: (json['added_members'] as List<dynamic>? ?? const [])
            .map((m) => ThreadMember.fromJson(m as Map<String, dynamic>))
            .toList(growable: false),
        removedMemberIds:
            (json['removed_member_ids'] as List<dynamic>? ?? const [])
                .map((id) => Snowflake.parse(id as String))
                .toList(growable: false),
      );

  final Snowflake threadId;
  final Snowflake guildId;

  /// Number of thread members after the change, capped at 50.
  final int memberCount;

  final List<ThreadMember> addedMembers;
  final List<Snowflake> removedMemberIds;

  @override
  String toString() =>
      'ThreadMembersUpdateEvent($threadId, +${addedMembers.length} '
      '-${removedMemberIds.length})';
}

/// Several messages deleted in one operation, from a bulk-delete call.
final class MessageDeleteBulkEvent extends GatewayEvent {
  const MessageDeleteBulkEvent({
    required this.messageIds,
    required this.channelId,
    required this.guildId,
  });

  /// The id list arrives under `ids`, not the `message_ids` key the
  /// bulk-delete request body uses.
  factory MessageDeleteBulkEvent.fromJson(Map<String, dynamic> json) =>
      MessageDeleteBulkEvent(
        messageIds: (json['ids'] as List<dynamic>)
            .map((id) => Snowflake.parse(id as String))
            .toList(growable: false),
        channelId: Snowflake.parse(json['channel_id'] as String),
        guildId: (json['guild_id'] as String?)?.let(Snowflake.parse),
      );

  final List<Snowflake> messageIds;
  final Snowflake channelId;

  /// `null` in a DM.
  final Snowflake? guildId;

  @override
  String toString() => 'MessageDeleteBulkEvent(${messageIds.length} messages)';
}

/// Every reaction cleared from a message at once.
final class MessageReactionRemoveAllEvent extends GatewayEvent {
  const MessageReactionRemoveAllEvent({
    required this.messageId,
    required this.channelId,
    required this.guildId,
  });

  factory MessageReactionRemoveAllEvent.fromJson(Map<String, dynamic> json) =>
      MessageReactionRemoveAllEvent(
        messageId: Snowflake.parse(json['message_id'] as String),
        channelId: Snowflake.parse(json['channel_id'] as String),
        guildId: (json['guild_id'] as String?)?.let(Snowflake.parse),
      );

  final Snowflake messageId;
  final Snowflake channelId;
  final Snowflake? guildId;

  @override
  String toString() => 'MessageReactionRemoveAllEvent($messageId)';
}

/// Every reaction using one specific emoji cleared from a message.
final class MessageReactionRemoveEmojiEvent extends GatewayEvent {
  const MessageReactionRemoveEmojiEvent({
    required this.messageId,
    required this.channelId,
    required this.emoji,
    required this.guildId,
  });

  factory MessageReactionRemoveEmojiEvent.fromJson(Map<String, dynamic> json) =>
      MessageReactionRemoveEmojiEvent(
        messageId: Snowflake.parse(json['message_id'] as String),
        channelId: Snowflake.parse(json['channel_id'] as String),
        emoji: ReactionEmoji.fromJson(json['emoji'] as Map<String, dynamic>),
        guildId: (json['guild_id'] as String?)?.let(Snowflake.parse),
      );

  final Snowflake messageId;
  final Snowflake channelId;
  final ReactionEmoji emoji;
  final Snowflake? guildId;

  @override
  String toString() => 'MessageReactionRemoveEmojiEvent($messageId, $emoji)';
}

/// A channel's pinned-message set changed.
///
/// Carries only the timestamp of the most recent pin, so acting on the
/// change means re-listing the channel's pins.
final class ChannelPinsUpdateEvent extends GatewayEvent {
  const ChannelPinsUpdateEvent({
    required this.channelId,
    required this.guildId,
    required this.lastPinTimestamp,
  });

  factory ChannelPinsUpdateEvent.fromJson(Map<String, dynamic> json) =>
      ChannelPinsUpdateEvent(
        channelId: Snowflake.parse(json['channel_id'] as String),
        guildId: (json['guild_id'] as String?)?.let(Snowflake.parse),
        lastPinTimestamp: (json['last_pin_timestamp'] as String?)?.let(
          DateTime.parse,
        ),
      );

  final Snowflake channelId;
  final Snowflake? guildId;

  /// `null` once the last pin is removed.
  final DateTime? lastPinTimestamp;

  @override
  String toString() => 'ChannelPinsUpdateEvent($channelId)';
}

/// A guild's emoji set was replaced.
///
/// The payload carries the full resulting collection rather than a delta,
/// so [emojis] is the guild's complete emoji list after the change.
final class GuildEmojisUpdateEvent extends GatewayEvent {
  const GuildEmojisUpdateEvent({required this.guildId, required this.emojis});

  factory GuildEmojisUpdateEvent.fromJson(Map<String, dynamic> json) =>
      GuildEmojisUpdateEvent(
        guildId: Snowflake.parse(json['guild_id'] as String),
        emojis: (json['emojis'] as List<dynamic>)
            .map((e) => GuildEmoji.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  final Snowflake guildId;
  final List<GuildEmoji> emojis;

  @override
  String toString() => 'GuildEmojisUpdateEvent(${emojis.length} emojis)';
}

/// A guild's sticker set was replaced. Like [GuildEmojisUpdateEvent], the
/// payload is the full resulting collection.
final class GuildStickersUpdateEvent extends GatewayEvent {
  const GuildStickersUpdateEvent({
    required this.guildId,
    required this.stickers,
  });

  factory GuildStickersUpdateEvent.fromJson(Map<String, dynamic> json) =>
      GuildStickersUpdateEvent(
        guildId: Snowflake.parse(json['guild_id'] as String),
        stickers: (json['stickers'] as List<dynamic>)
            .map((e) => GuildSticker.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  final Snowflake guildId;
  final List<GuildSticker> stickers;

  @override
  String toString() => 'GuildStickersUpdateEvent(${stickers.length} stickers)';
}

/// An audit log entry was written.
///
/// Delivered to sessions holding `viewAuditLog`, and carries the same
/// entry shape the audit log REST route returns plus the originating
/// guild and, for some action types, a `changes` array the REST model
/// does not expose.
final class GuildAuditLogEntryCreateEvent extends GatewayEvent {
  const GuildAuditLogEntryCreateEvent({
    required this.guildId,
    required this.entry,
    required this.changes,
  });

  factory GuildAuditLogEntryCreateEvent.fromJson(Map<String, dynamic> json) =>
      GuildAuditLogEntryCreateEvent(
        guildId: Snowflake.parse(json['guild_id'] as String),
        entry: GuildAuditLogEntry.fromJson(json),
        changes:
            (json['changes'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .toList(growable: false) ??
            const [],
      );

  final Snowflake guildId;
  final GuildAuditLogEntry entry;

  /// Raw `{key, old_value, new_value}` objects. The value types depend on
  /// which field changed, so they stay undecoded.
  final List<Map<String, dynamic>> changes;

  @override
  String toString() => 'GuildAuditLogEntryCreateEvent(${entry.actionType})';
}

/// A channel's webhook set changed.
///
/// Carries no webhook data at all, so acting on it means re-listing the
/// channel's webhooks.
final class WebhooksUpdateEvent extends GatewayEvent {
  const WebhooksUpdateEvent({required this.channelId, required this.guildId});

  factory WebhooksUpdateEvent.fromJson(Map<String, dynamic> json) =>
      WebhooksUpdateEvent(
        channelId: Snowflake.parse(json['channel_id'] as String),
        guildId: Snowflake.parse(json['guild_id'] as String),
      );

  final Snowflake channelId;
  final Snowflake guildId;

  @override
  String toString() => 'WebhooksUpdateEvent($channelId)';
}

/// An invite was created.
///
/// The payload nests partial `channel` and `guild` objects rather than
/// repeating the full resources, so only their ids are decoded here.
final class InviteCreateEvent extends GatewayEvent {
  const InviteCreateEvent({
    required this.code,
    required this.channelId,
    required this.guildId,
    required this.inviter,
    required this.createdAt,
    required this.expiresAt,
    required this.maxAge,
    required this.maxUses,
  });

  factory InviteCreateEvent.fromJson(Map<String, dynamic> json) =>
      InviteCreateEvent(
        code: json['code'] as String,
        channelId: Snowflake.parse(
          (json['channel'] as Map<String, dynamic>)['id'] as String,
        ),
        guildId: (json['guild_id'] as String?)?.let(Snowflake.parse),
        inviter: (json['inviter'] as Map<String, dynamic>?)?.let(User.fromJson),
        createdAt: DateTime.parse(json['created_at'] as String),
        expiresAt: (json['expires_at'] as String?)?.let(DateTime.parse),
        maxAge: json['max_age'] as int?,
        maxUses: json['max_uses'] as int?,
      );

  final String code;
  final Snowflake channelId;
  final Snowflake? guildId;

  /// `null` for an invite created by a route that does not attribute one.
  final User? inviter;
  final DateTime createdAt;

  /// `null` for an invite that never expires.
  final DateTime? expiresAt;

  /// Lifetime in seconds; `0` means no expiry.
  final int? maxAge;

  /// `0` means unlimited uses.
  final int? maxUses;

  @override
  String toString() => 'InviteCreateEvent($code)';
}

/// An invite was deleted or expired.
final class InviteDeleteEvent extends GatewayEvent {
  const InviteDeleteEvent({
    required this.code,
    required this.channelId,
    required this.guildId,
  });

  factory InviteDeleteEvent.fromJson(Map<String, dynamic> json) =>
      InviteDeleteEvent(
        code: json['code'] as String,
        channelId: Snowflake.parse(json['channel_id'] as String),
        guildId: (json['guild_id'] as String?)?.let(Snowflake.parse),
      );

  final String code;
  final Snowflake channelId;
  final Snowflake? guildId;

  @override
  String toString() => 'InviteDeleteEvent($code)';
}

/// The account's set of live gateway sessions was replaced.
///
/// The payload is a bare JSON array rather than an object, and it
/// describes every session on the account, not just this one. It arrives
/// whenever another session for the same token connects or disconnects,
/// which for a bot most often means a reconnect leaving a stale entry
/// behind.
final class SessionsReplaceEvent extends GatewayEvent {
  const SessionsReplaceEvent(this.sessions);

  factory SessionsReplaceEvent.fromJson(Object? payload) =>
      SessionsReplaceEvent(switch (payload) {
        final List<dynamic> entries =>
          entries
              .whereType<Map<String, dynamic>>()
              .map(SessionPresence.fromJson)
              .toList(growable: false),
        _ => const [],
      });

  final List<SessionPresence> sessions;

  /// The per-connection entries, excluding the account-wide aggregate.
  Iterable<SessionPresence> get connections =>
      sessions.where((s) => !s.isAggregate);

  /// The account-wide aggregate entry, when present.
  SessionPresence? get aggregate =>
      sessions.where((s) => s.isAggregate).firstOrNull;

  @override
  String toString() => 'SessionsReplaceEvent(${sessions.length} sessions)';
}

/// A DISPATCH event whose name is not modelled by this version of
/// `fluxer_dart_gateway`.
///
/// Carries the raw event name and payload so a caller can still branch on
/// [eventName] without a typed variant. [data] is `Object?` because a
/// dispatch payload is not guaranteed to be a JSON object.
final class UnknownDispatchEvent extends GatewayEvent {
  const UnknownDispatchEvent(this.eventName, this.data);

  final String eventName;

  /// Usually a `Map<String, dynamic>`, but an array or scalar for events
  /// that send one.
  final Object? data;

  @override
  String toString() => 'UnknownDispatchEvent($eventName)';
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
