import 'package:fluxer_dart_core/fluxer_dart_core.dart';

/// A group header in a member list: a hoisted role id, `online`, or
/// `offline`.
final class MemberListGroup {
  const MemberListGroup({required this.id, required this.count});

  factory MemberListGroup.fromJson(Map<String, dynamic> json) =>
      MemberListGroup(id: json['id'] as String, count: json['count'] as int);

  final String id;
  final int count;

  bool get isOnline => id == 'online';
  bool get isOffline => id == 'offline';

  @override
  String toString() => 'MemberListGroup($id, $count)';
}

/// One position in a member list: a group header or a member.
sealed class MemberListItem {
  const MemberListItem();

  /// `null` for an item shape this package does not know.
  static MemberListItem? fromJson(Map<String, dynamic> json) {
    if (json['group'] case final Map<String, dynamic> group) {
      return MemberListGroupItem(MemberListGroup.fromJson(group));
    }
    if (json['member'] case final Map<String, dynamic> member) {
      final decoded = GuildMember.fromJson(member);
      return MemberListMemberItem(
        decoded,
        UserPresence.fromJson(
          member['presence'] as Map<String, dynamic>,
          user: decoded.user,
        ),
      );
    }
    return null;
  }
}

final class MemberListGroupItem extends MemberListItem {
  const MemberListGroupItem(this.group);

  final MemberListGroup group;
}

/// A member, with their presence; an offline member's presence has
/// status [PresenceStatus.offline].
final class MemberListMemberItem extends MemberListItem {
  const MemberListMemberItem(this.member, this.presence);

  final GuildMember member;
  final UserPresence presence;
}

/// Replaces the inclusive range [start]..[end] of a member list with
/// [items]. `SYNC` is the only operation the server sends.
final class MemberListOperation {
  const MemberListOperation({
    required this.op,
    required this.start,
    required this.end,
    required this.items,
  });

  factory MemberListOperation.fromJson(Map<String, dynamic> json) {
    final range = (json['range'] as List<dynamic>?)?.cast<int>() ?? const [];
    return MemberListOperation(
      op: json['op'] as String,
      start: range.isNotEmpty ? range[0] : 0,
      end: range.length > 1 ? range[1] : 0,
      items: [
        for (final item in json['items'] as List<dynamic>? ?? const [])
          ?MemberListItem.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  final String op;
  final int start;
  final int end;
  final List<MemberListItem> items;

  bool get isSync => op == 'SYNC';
}

/// One member of a subscribed thread member list.
final class ThreadMemberListEntry {
  const ThreadMemberListEntry({required this.member, required this.presence});

  factory ThreadMemberListEntry.fromJson(Map<String, dynamic> json) {
    final member = ThreadMember.fromJson(json);
    final user = member.member?.user;
    final presence = json['presence'] as Map<String, dynamic>?;
    return ThreadMemberListEntry(
      member: member,
      presence: presence == null || (presence['user'] == null && user == null)
          ? null
          : UserPresence.fromJson(presence, user: user),
    );
  }

  final ThreadMember member;

  /// `null` only for an offline user whose guild member was not sent,
  /// since the offline placeholder names no user.
  final UserPresence? presence;
}

/// One guild's entry in `GUILD_COUNTS_UPDATE`.
final class GuildCounts {
  const GuildCounts({
    required this.guildId,
    required this.memberCount,
    required this.onlineCount,
  });

  factory GuildCounts.fromJson(Map<String, dynamic> json) => GuildCounts(
    guildId: Snowflake.parse(json['guild_id'] as String),
    memberCount: json['member_count'] as int,
    onlineCount: json['online_count'] as int,
  );

  final Snowflake guildId;
  final int memberCount;

  /// Online members sharing a channel this bot can view; the whole
  /// guild's online count for a bot holding `administrator`.
  final int onlineCount;

  @override
  String toString() => 'GuildCounts($guildId, $onlineCount/$memberCount)';
}

/// One channel's entry in `CHANNEL_MEMBER_COUNTS_UPDATE`.
final class ChannelMemberCounts {
  const ChannelMemberCounts({
    required this.guildId,
    required this.channelId,
    required this.memberCount,
    required this.onlineCount,
  });

  factory ChannelMemberCounts.fromJson(Map<String, dynamic> json) =>
      ChannelMemberCounts(
        guildId: Snowflake.parse(json['guild_id'] as String),
        channelId: Snowflake.parse(json['channel_id'] as String),
        memberCount: json['member_count'] as int,
        onlineCount: json['online_count'] as int,
      );

  final Snowflake guildId;
  final Snowflake channelId;

  /// Members that can view the channel.
  final int memberCount;
  final int onlineCount;

  @override
  String toString() =>
      'ChannelMemberCounts($channelId, $onlineCount/$memberCount)';
}

/// One post's entry in `FORUM_UNREADS`: [count] messages after the
/// acknowledged one, capped at 25, or [missing] when no acknowledged
/// message was sent.
final class ForumUnread {
  const ForumUnread({required this.threadId, this.count, this.missing = false});

  factory ForumUnread.fromJson(Map<String, dynamic> json) => ForumUnread(
    threadId: Snowflake.parse(json['thread_id'] as String),
    count: json['count'] as int?,
    missing: json['missing'] as bool? ?? false,
  );

  final Snowflake threadId;
  final int? count;
  final bool missing;

  @override
  String toString() => 'ForumUnread($threadId, ${missing ? 'missing' : count})';
}
