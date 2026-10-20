import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_gateway/fluxer_dart_gateway.dart';
import 'package:test/test.dart';

/// Payloads in this file are recorded from a live bot session that sent
/// no session flags, so they are what a bot receives without opting in
/// to anything.
void main() {
  const thread = <String, dynamic>{
    'flags': 0,
    'guild_id': '1536791058510249984',
    'id': '1558481243627061250',
    'last_message_id': null,
    'last_pin_timestamp': null,
    'member_count': 1,
    'message_count': 0,
    'name': 'probe public',
    'owner_id': '1536790964075495424',
    'parent_id': '1536791058510249987',
    'rate_limit_per_user': 0,
    'thread_metadata': {
      'archive_timestamp': '2026-10-10T14:08:03.771Z',
      'archived': false,
      'auto_archive_duration': 4320,
      'create_timestamp': '2026-10-10T14:08:03.771Z',
      'locked': false,
    },
    'total_message_sent': 0,
    'type': 11,
  };
  const ownMember = <String, dynamic>{
    'flags': 0,
    'id': '1558481243627061250',
    'join_timestamp': '2026-10-10T14:08:03.771Z',
    'mute_config': null,
    'muted': false,
    'user_id': '1536790964075495424',
  };

  group('THREAD_CREATE', () {
    test('a new thread sets newly_created and carries own membership', () {
      final event =
          GatewayEvent.fromDispatch('THREAD_CREATE', {
                ...thread,
                'member': ownMember,
                'newly_created': true,
              })
              as ThreadCreateEvent;

      expect(event.newlyCreated, isTrue);
      expect(event.thread.name, 'probe public');
      expect(event.thread.type, ChannelType.publicThread);
      expect(
        event.thread.member?.userId,
        Snowflake.parse('1536790964075495424'),
      );
    });

    test('joining an existing thread omits newly_created', () {
      final event =
          GatewayEvent.fromDispatch('THREAD_CREATE', {
                ...thread,
                'member': ownMember,
              })
              as ThreadCreateEvent;

      expect(event.newlyCreated, isFalse);
    });
  });

  test('THREAD_UPDATE carries the whole thread, not a partial', () {
    final event =
        GatewayEvent.fromDispatch('THREAD_UPDATE', {
              ...thread,
              'name': 'probe renamed',
              'thread_metadata': {
                'archive_timestamp': '2026-10-10T14:08:30.700Z',
                'archived': true,
                'auto_archive_duration': 4320,
                'create_timestamp': '2026-10-10T14:08:03.771Z',
                'locked': false,
              },
            })
            as ThreadUpdateEvent;

    expect(event.thread.name, 'probe renamed');
    expect(event.thread.isArchived, isTrue);
    expect(event.thread.parentId, Snowflake.parse('1536791058510249987'));
  });

  test('THREAD_DELETE carries ids and the type only', () {
    final event =
        GatewayEvent.fromDispatch('THREAD_DELETE', {
              'guild_id': '1536791058510249984',
              'id': '1558481243262156800',
              'parent_id': '1536791058510249987',
              'type': 11,
            })
            as ThreadDeleteEvent;

    expect(event.threadId, Snowflake.parse('1558481243262156800'));
    expect(event.guildId, Snowflake.parse('1536791058510249984'));
    expect(event.parentId, Snowflake.parse('1536791058510249987'));
    expect(event.threadType, ChannelType.publicThread);
  });

  test('THREAD_MEMBER_UPDATE is the own member object plus guild_id', () {
    final event =
        GatewayEvent.fromDispatch('THREAD_MEMBER_UPDATE', {
              ...ownMember,
              'flags': 1,
              'guild_id': '1536791058510249984',
            })
            as ThreadMemberUpdateEvent;

    expect(event.guildId, Snowflake.parse('1536791058510249984'));
    expect(event.member.threadId, Snowflake.parse('1558481243627061250'));
    expect(event.member.hasFlag(ThreadMemberFlag.hasInteracted), isTrue);
    expect(event.member.muted, isFalse);
  });

  group('THREAD_MEMBERS_UPDATE', () {
    test('an addition embeds the guild member with its user', () {
      final event =
          GatewayEvent.fromDispatch('THREAD_MEMBERS_UPDATE', {
                'added_members': [
                  {
                    'flags': 0,
                    'id': '1558481243627061253',
                    'join_timestamp': '2026-10-10T14:08:30.070Z',
                    'member': {
                      'accent_color': null,
                      'avatar': null,
                      'banner': null,
                      'communication_disabled_until': null,
                      'deaf': false,
                      'joined_at': '2026-08-11T17:39:00.546Z',
                      'mute': false,
                      'nick': null,
                      'roles': <dynamic>[],
                      'user': {
                        'avatar': null,
                        'avatar_color': null,
                        'discriminator': '3221',
                        'flags': 0,
                        'global_name': 'Oppa',
                        'id': '1536790890901667840',
                        'username': 'oppa',
                      },
                    },
                    'presence': null,
                    'user_id': '1536790890901667840',
                  },
                ],
                'guild_id': '1536791058510249984',
                'id': '1558481243627061253',
                'member_count': 2,
              })
              as ThreadMembersUpdateEvent;

      expect(event.threadId, Snowflake.parse('1558481243627061253'));
      expect(event.memberCount, 2);
      expect(event.removedMemberIds, isEmpty);
      final added = event.addedMembers.single;
      expect(added.userId, Snowflake.parse('1536790890901667840'));
      expect(added.member?.user.username, 'oppa');
      expect(added.muted, isNull);
    });

    test('a removal names ids only', () {
      final event =
          GatewayEvent.fromDispatch('THREAD_MEMBERS_UPDATE', {
                'guild_id': '1536791058510249984',
                'id': '1558481243627061253',
                'member_count': 1,
                'removed_member_ids': ['1536790890901667840'],
              })
              as ThreadMembersUpdateEvent;

      expect(event.addedMembers, isEmpty);
      expect(event.removedMemberIds, [Snowflake.parse('1536790890901667840')]);
      expect(event.memberCount, 1);
    });
  });

  group('THREAD_LIST_SYNC', () {
    test('a full sync carries no channel_ids', () {
      final event =
          GatewayEvent.fromDispatch('THREAD_LIST_SYNC', {
                'guild_id': '1536791058510249984',
                'members': [
                  {
                    'flags': 0,
                    'id': '1562157554690162688',
                    'join_timestamp': '2026-10-20T17:36:24.580Z',
                    'mute_config': null,
                    'muted': false,
                    'user_id': '1536790964075495424',
                  },
                ],
                'threads': [
                  {
                    'flags': 0,
                    'guild_id': '1536791058510249984',
                    'id': '1562157554690162688',
                    'last_message_id': null,
                    'last_pin_timestamp': null,
                    'member_count': 1,
                    'message_count': 0,
                    'name': 'rec-thread',
                    'owner_id': '1536790964075495424',
                    'parent_id': '1562157554274926592',
                    'rate_limit_per_user': 0,
                    'thread_metadata': {
                      'archive_timestamp': '2026-10-20T17:36:24.580Z',
                      'archived': false,
                      'auto_archive_duration': 4320,
                      'create_timestamp': '2026-10-20T17:36:24.580Z',
                      'locked': false,
                    },
                    'total_message_sent': 0,
                    'type': 11,
                  },
                ],
              })
              as ThreadListSyncEvent;

      expect(event.guildId, Snowflake.parse('1536791058510249984'));
      expect(event.channelIds, isNull);
      expect(event.threads.single.name, 'rec-thread');
      expect(
        event.threads.single.parentId,
        Snowflake.parse('1562157554274926592'),
      );
      expect(
        event.members.single.threadId,
        Snowflake.parse('1562157554690162688'),
      );
      expect(
        event.members.single.userId,
        Snowflake.parse('1536790964075495424'),
      );
    });

    // Not observed on a live session; shaped from the reference.
    test('channel_ids scopes the replacement to those channels', () {
      final event =
          GatewayEvent.fromDispatch('THREAD_LIST_SYNC', {
                'guild_id': '1536791058510249984',
                'channel_ids': ['1536791058510249987'],
                'threads': [thread],
                'members': [ownMember],
              })
              as ThreadListSyncEvent;

      expect(event.channelIds, [Snowflake.parse('1536791058510249987')]);
      expect(event.threads.single.name, 'probe public');
      expect(
        event.members.single.threadId,
        Snowflake.parse('1558481243627061250'),
      );
    });

    test('channelIds is null when the whole guild is replaced', () {
      final event =
          GatewayEvent.fromDispatch('THREAD_LIST_SYNC', {
                'guild_id': '1536791058510249984',
                'threads': <dynamic>[],
                'members': <dynamic>[],
              })
              as ThreadListSyncEvent;

      expect(event.channelIds, isNull);
    });
  });

  group('GUILD_CREATE threads', () {
    Map<String, dynamic> guildCreate(Object? threads) => {
      'id': '1536791058510249984',
      'properties': {'name': 'g', 'icon': null, 'owner_id': '1'},
      'roles': <dynamic>[],
      'member_count': 2,
      'threads': ?threads,
    };

    test('active threads decode, with an id-less own member', () {
      final event =
          GatewayEvent.fromDispatch(
                'GUILD_CREATE',
                guildCreate([
                  {
                    ...thread,
                    'member': {
                      'flags': 1,
                      'join_timestamp': '2026-10-10T14:08:16.657Z',
                      'mute_config': null,
                      'muted': false,
                    },
                  },
                ]),
              )
              as GuildCreateEvent;

      final decoded = event.threads.single;
      expect(decoded.name, 'probe public');
      expect(decoded.member, isNotNull);
      expect(decoded.member!.threadId, isNull);
      expect(decoded.member!.userId, isNull);
    });

    test('a payload without threads decodes to an empty list', () {
      final event =
          GatewayEvent.fromDispatch('GUILD_CREATE', guildCreate(null))
              as GuildCreateEvent;

      expect(event.threads, isEmpty);
      expect(event.guild.name, 'g');
    });
  });

  test('a thread message decodes as an ordinary MESSAGE_CREATE', () {
    final event =
        GatewayEvent.fromDispatch('MESSAGE_CREATE', {
              'attachments': <dynamic>[],
              'author': {
                'avatar': null,
                'avatar_color': null,
                'bot': true,
                'discriminator': '9784',
                'flags': 0,
                'global_name': null,
                'id': '1536790964075495424',
                'username': 'MarlinMammut',
              },
              'channel_id': '1558481243627061253',
              'channel_type': 12,
              'content': '',
              'edited_timestamp': null,
              'embeds': <dynamic>[],
              'flags': 0,
              'guild_id': '1536791058510249984',
              'id': '1558481354419601408',
              'mention_everyone': false,
              'mention_roles': <dynamic>[],
              'mentions': <dynamic>[],
              'pinned': false,
              'stickers': <dynamic>[],
              'timestamp': '2026-10-10T14:08:30.077Z',
              'tts': false,
              'type': 1,
            })
            as MessageCreateEvent;

    expect(event.message.type, MessageType.recipientAdd);
    expect(event.message.channelId, Snowflake.parse('1558481243627061253'));
  });

  test('opcode 28 and the thread session flag', () {
    expect(GatewayOpcode.fromValue(28), GatewayOpcode.requestForumUnreads);
    expect(SessionFlag.channelThreads.bit, 4);
    expect(
      SessionFlags.of([
        SessionFlag.debounceMessageReactions,
        SessionFlag.channelThreads,
      ]).value,
      6,
    );
  });
}
