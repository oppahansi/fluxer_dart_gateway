import 'package:fluxer_dart_core/fluxer_dart_core.dart';

/// A decoded DISPATCH (opcode 0) payload.
///
/// Sealed so consumers get exhaustive-`switch` safety instead of Fluxer's
/// own client's untyped `Map<string, handler>` event registry. Covers
/// session lifecycle (READY, RESUMED) and the ~18 events that cover
/// typical moderation/utility bot needs (message edits/deletes/reactions,
/// channel and role CRUD, member join/leave, bans, typing). The remaining
/// events (presence, voice states, calls, invites, webhooks update, the
/// Fluxer-only meme/saved-message events, ...) still decode to
/// [UnknownDispatchEvent] rather than being dropped, so a bot author can
/// still react to them by name before a typed variant exists.
///
/// Several "update"/"remove" events carry a genuinely **partial**
/// payload, not a full resource. Some of that was caught cross-checking
/// the reference client's TS handlers (`fluxer_app/src/features/**/
/// events/*.ts`) against their own unchecked `as` casts
/// (`ChannelUpdateEvent`, `MessageUpdateEvent`); `GuildMemberRemoveEvent`/
/// `GuildBanAddEvent`/`GuildBanRemoveEvent` looked fully-typed by the
/// same TS check but turned out to only carry `{id}` for their `user`
/// field on the real wire — caught by a live cast-error crash, not by
/// reading source, so carry just [Snowflake] ids now instead of a
/// decoded [User]. The lesson generalizes: a TS type on the reference
/// client is what it *claims* to send, not proof of what it actually
/// does.
sealed class GatewayEvent {
  const GatewayEvent();

  /// Decodes a raw `{t: eventName, d: payload}` DISPATCH body into a typed
  /// event, or [UnknownDispatchEvent] if [eventName] isn't modeled yet.
  factory GatewayEvent.fromDispatch(
    String eventName,
    Map<String, dynamic> data,
  ) {
    return switch (eventName) {
      'READY' => ReadyEvent.fromJson(data),
      'RESUMED' => const ResumedEvent(),
      'MESSAGE_CREATE' => MessageCreateEvent(Message.fromJson(data)),
      'MESSAGE_UPDATE' => MessageUpdateEvent.fromJson(data),
      'MESSAGE_DELETE' => MessageDeleteEvent.fromJson(data),
      'MESSAGE_REACTION_ADD' => MessageReactionAddEvent.fromJson(data),
      'MESSAGE_REACTION_REMOVE' => MessageReactionRemoveEvent.fromJson(data),
      'TYPING_START' => TypingStartEvent.fromJson(data),
      'GUILD_CREATE' => GuildCreateEvent(Guild.fromGuildCreateJson(data)),
      'GUILD_UPDATE' => GuildUpdateEvent(Guild.fromJson(data)),
      'GUILD_DELETE' => GuildDeleteEvent.fromJson(data),
      'GUILD_ROLE_CREATE' => GuildRoleCreateEvent.fromJson(data),
      'GUILD_ROLE_UPDATE' => GuildRoleUpdateEvent.fromJson(data),
      'GUILD_ROLE_DELETE' => GuildRoleDeleteEvent.fromJson(data),
      'GUILD_MEMBER_ADD' => GuildMemberAddEvent.fromJson(data),
      'GUILD_MEMBER_UPDATE' => GuildMemberUpdateEvent.fromJson(data),
      'GUILD_MEMBER_REMOVE' => GuildMemberRemoveEvent.fromJson(data),
      'GUILD_BAN_ADD' => GuildBanAddEvent.fromJson(data),
      'GUILD_BAN_REMOVE' => GuildBanRemoveEvent.fromJson(data),
      'CHANNEL_CREATE' => ChannelCreateEvent(Channel.fromJson(data)),
      'CHANNEL_UPDATE' => ChannelUpdateEvent.fromJson(data),
      'CHANNEL_DELETE' => ChannelDeleteEvent.fromJson(data),
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
  const GuildCreateEvent(this.guild);

  final Guild guild;

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

/// A DISPATCH event whose name isn't modeled by this version of
/// `fluxer_dart_gateway`. Carries the raw event name and payload so callers can
/// still branch on [eventName] without a typed variant.
final class UnknownDispatchEvent extends GatewayEvent {
  const UnknownDispatchEvent(this.eventName, this.data);

  final String eventName;
  final Map<String, dynamic> data;

  @override
  String toString() => 'UnknownDispatchEvent($eventName)';
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
