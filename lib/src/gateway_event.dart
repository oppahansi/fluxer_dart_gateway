import 'package:fluxer_core/fluxer_core.dart';

/// A decoded DISPATCH (opcode 0) payload.
///
/// Sealed so consumers get exhaustive-`switch` safety instead of Fluxer's
/// own client's untyped `Map<string, handler>` event registry. M1 types
/// the four events the "hello gateway" vertical slice needs; the other
/// ~50 event names verified in `EventRouter.ts` (`GUILD_UPDATE`,
/// `MESSAGE_REACTION_ADD`, `TYPING_START`, ...) decode to
/// [UnknownDispatchEvent] for now rather than being dropped, so a bot
/// author can still react to them by name before a typed variant exists.
/// Broadened in M3.
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
      'GUILD_CREATE' => GuildCreateEvent(Guild.fromGuildCreateJson(data)),
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

/// A DISPATCH event whose name isn't modeled by this version of
/// `fluxer_gateway` yet. Carries the raw event name and payload so callers
/// that need it can still branch on [eventName] while a proper typed
/// variant is added in a later milestone.
final class UnknownDispatchEvent extends GatewayEvent {
  const UnknownDispatchEvent(this.eventName, this.data);

  final String eventName;
  final Map<String, dynamic> data;

  @override
  String toString() => 'UnknownDispatchEvent($eventName)';
}
