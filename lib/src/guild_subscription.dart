import 'package:fluxer_dart_core/fluxer_dart_core.dart';

/// One guild's entry in a Lazy Request (opcode 14). Only the options set
/// are sent; the server keeps each guild's options for the session and
/// reapplies them when the guild reconnects.
///
/// A bot session is never passive, so [active] changes nothing for a
/// bot. What a bot uses this for is [members] (the only way it receives
/// `PRESENCE_UPDATE`), [memberListChannels] (`GUILD_MEMBER_LIST_UPDATE`),
/// [typing], [sync] and [threadMemberLists].
final class GuildSubscription {
  const GuildSubscription({
    this.active,
    this.sync,
    this.typing,
    this.memberListChannels,
    this.members,
    this.threads,
    this.threadMemberLists,
  });

  final bool? active;

  /// Asks for a `GUILD_SYNC`. Dropped when the guild is already synced
  /// for this session.
  final bool? sync;

  /// Whether the guild delivers `TYPING_START` to this session.
  final bool? typing;

  /// Member list windows per channel, each an inclusive `(start, end)`
  /// with `end - start` at most 99 and at most 10 per channel.
  /// Subscribing one channel drops this session's other member list in
  /// the guild; an empty list clears the channel's ranges.
  final Map<Snowflake, List<(int, int)>>? memberListChannels;

  /// Members whose presence to receive, at most 1,000.
  final List<Snowflake>? members;

  final bool? threads;

  /// Threads whose member lists to receive, at most 10. Replaces the
  /// previous list; an empty list clears it.
  final List<Snowflake>? threadMemberLists;

  Map<String, dynamic> toJson() => {
    'active': ?active,
    'sync': ?sync,
    'typing': ?typing,
    if (memberListChannels != null)
      'member_list_channels': {
        for (final MapEntry(:key, :value) in memberListChannels!.entries)
          key.toJson(): [
            for (final (start, end) in value) [start, end],
          ],
      },
    if (members != null) 'members': [for (final id in members!) id.toJson()],
    'threads': ?threads,
    if (threadMemberLists != null)
      'thread_member_lists': [for (final id in threadMemberLists!) id.toJson()],
  };
}

/// One post in a Request Forum Unreads (opcode 28): count the messages in
/// [threadId] after [ackMessageId], or report it `missing` without one.
final class ForumUnreadRequest {
  const ForumUnreadRequest(this.threadId, {this.ackMessageId});

  final Snowflake threadId;
  final Snowflake? ackMessageId;

  Map<String, dynamic> toJson() => {
    'thread_id': threadId.toJson(),
    if (ackMessageId != null) 'ack_message_id': ackMessageId!.toJson(),
  };
}
