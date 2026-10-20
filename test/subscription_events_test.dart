import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_gateway/fluxer_dart_gateway.dart';
import 'package:test/test.dart';

// Recorded from a live bot session: GUILD_CREATE with an emoji and a
// sticker present, then a Lazy Request with sync, a member list window
// and a thread member list, guild and channel counts, and forum unreads
// with and without an acknowledged message.
const _guildCreate = {
  'channels': [
    {
      'content_warning_level': 0,
      'content_warning_text': null,
      'guild_id': '1536791058510249984',
      'id': '1536791058510249985',
      'name': 'Text Channels',
      'nsfw': false,
      'nsfw_override': false,
      'permission_overwrites': <dynamic>[],
      'position': 2,
      'type': 4,
    },
    {
      'content_warning_level': 0,
      'content_warning_text': null,
      'guild_id': '1536791058510249984',
      'id': '1536791058510249986',
      'name': 'Voice Channels',
      'nsfw': false,
      'nsfw_override': false,
      'permission_overwrites': <dynamic>[],
      'position': 4,
      'type': 4,
    },
    {
      'content_warning_level': 0,
      'content_warning_text': null,
      'guild_id': '1536791058510249984',
      'id': '1536791058510249987',
      'last_message_id': '1562165912151261184',
      'last_pin_timestamp': '2026-09-07T21:09:08.756Z',
      'name': 'general',
      'nsfw': false,
      'nsfw_override': false,
      'parent_id': '1536791058510249985',
      'permission_overwrites': <dynamic>[],
      'position': 3,
      'rate_limit_per_user': 0,
      'topic': null,
      'type': 0,
    },
    {
      'bitrate': 64000,
      'content_warning_level': 0,
      'content_warning_text': null,
      'guild_id': '1536791058510249984',
      'id': '1536791058510249988',
      'last_message_id': null,
      'last_pin_timestamp': null,
      'name': 'General',
      'nsfw': false,
      'nsfw_override': false,
      'parent_id': '1536791058510249986',
      'permission_overwrites': <dynamic>[],
      'position': 5,
      'rate_limit_per_user': 0,
      'rtc_p2p': false,
      'rtc_region': null,
      'topic': null,
      'type': 2,
      'user_limit': 0,
      'voice_connection_limit': 5,
    },
  ],
  'emojis': [
    {
      'animated': false,
      'id': '1562166598674939904',
      'name': 'recgc',
      'nsfw': false,
    },
  ],
  'id': '1536791058510249984',
  'joined_at': '2026-08-12T06:10:10.527Z',
  'member_count': 2,
  'members': [
    {
      'accent_color': null,
      'avatar': null,
      'banner': null,
      'communication_disabled_until': null,
      'deaf': false,
      'guild_id': '1536791058510249984',
      'joined_at': '2026-08-12T06:10:10.527Z',
      'mute': false,
      'nick': null,
      'roles': ['1546623715096133632'],
      'user': {
        'avatar': null,
        'avatar_color': null,
        'bot': true,
        'discriminator': '9784',
        'flags': 0,
        'global_name': null,
        'id': '1536790964075495424',
        'username': 'MarlinMammut',
      },
    },
  ],
  'online_count': 2,
  'presences': <dynamic>[],
  'properties': {
    'afk_channel_id': null,
    'afk_timeout': 300,
    'banner': null,
    'banner_height': null,
    'banner_width': null,
    'content_warning_level': 0,
    'content_warning_text': null,
    'default_message_notifications': 0,
    'disabled_operations': 0,
    'embed_splash': null,
    'embed_splash_height': null,
    'embed_splash_width': null,
    'explicit_content_filter': 0,
    'features': ['ANIMATED_ICON', 'ANIMATED_BANNER', 'BANNER', 'INVITE_SPLASH'],
    'icon': null,
    'id': '1536791058510249984',
    'message_history_cutoff': null,
    'mfa_level': 0,
    'name': 'fluxer.dart test server',
    'nsfw': false,
    'nsfw_level': 0,
    'owner_id': '1536790890901667840',
    'rules_channel_id': null,
    'splash': null,
    'splash_card_alignment': 0,
    'splash_height': null,
    'splash_width': null,
    'system_channel_flags': 0,
    'system_channel_id': '1536791058510249987',
    'vanity_url_code': null,
    'verification_level': 0,
  },
  'roles': [
    {
      'color': 0,
      'hoist': false,
      'hoist_position': null,
      'id': '1536791058510249984',
      'mentionable': false,
      'name': '@everyone',
      'permissions': '18014914009747009',
      'position': 0,
    },
    {
      'color': 0,
      'hoist': false,
      'hoist_position': null,
      'id': '1536804370778161152',
      'mentionable': false,
      'name': 'M3 Test Role',
      'permissions': '18014536052624961',
      'position': 4,
    },
    {
      'color': 0,
      'hoist': false,
      'hoist_position': null,
      'id': '1546623715096133632',
      'mentionable': false,
      'name': 'sdk-capture-admin',
      'permissions': '8',
      'position': 3,
    },
  ],
  'stickers': [
    {
      'animated': false,
      'description': '',
      'id': '1562166598674939906',
      'name': 'recgc',
      'nsfw': false,
      'tags': ['test'],
    },
  ],
  'threads': <dynamic>[],
  'unavailable': false,
  'voice_states': <dynamic>[],
};

const _guildSync = {
  'channels': [
    {
      'content_warning_level': 0,
      'content_warning_text': null,
      'guild_id': '1536791058510249984',
      'id': '1536791058510249985',
      'name': 'Text Channels',
      'nsfw': false,
      'nsfw_override': false,
      'permission_overwrites': <dynamic>[],
      'position': 2,
      'type': 4,
    },
    {
      'content_warning_level': 0,
      'content_warning_text': null,
      'guild_id': '1536791058510249984',
      'id': '1536791058510249986',
      'name': 'Voice Channels',
      'nsfw': false,
      'nsfw_override': false,
      'permission_overwrites': <dynamic>[],
      'position': 4,
      'type': 4,
    },
    {
      'content_warning_level': 0,
      'content_warning_text': null,
      'guild_id': '1536791058510249984',
      'id': '1536791058510249987',
      'last_message_id': '1558489734500581376',
      'last_pin_timestamp': '2026-09-07T21:09:08.756Z',
      'name': 'general',
      'nsfw': false,
      'nsfw_override': false,
      'parent_id': '1536791058510249985',
      'permission_overwrites': <dynamic>[],
      'position': 3,
      'rate_limit_per_user': 0,
      'topic': null,
      'type': 0,
    },
    {
      'bitrate': 64000,
      'content_warning_level': 0,
      'content_warning_text': null,
      'guild_id': '1536791058510249984',
      'id': '1536791058510249988',
      'last_message_id': null,
      'last_pin_timestamp': null,
      'name': 'General',
      'nsfw': false,
      'nsfw_override': false,
      'parent_id': '1536791058510249986',
      'permission_overwrites': <dynamic>[],
      'position': 5,
      'rate_limit_per_user': 0,
      'rtc_p2p': false,
      'rtc_region': null,
      'topic': null,
      'type': 2,
      'user_limit': 0,
      'voice_connection_limit': 5,
    },
  ],
  'emojis': <dynamic>[],
  'id': '1536791058510249984',
  'joined_at': '2026-08-12T06:10:10.527Z',
  'member_count': 2,
  'members': [
    {
      'accent_color': null,
      'avatar': null,
      'banner': null,
      'communication_disabled_until': null,
      'deaf': false,
      'guild_id': '1536791058510249984',
      'joined_at': '2026-08-12T06:10:10.527Z',
      'mute': false,
      'nick': null,
      'roles': ['1546623715096133632'],
      'user': {
        'avatar': null,
        'avatar_color': null,
        'bot': true,
        'discriminator': '9784',
        'flags': 0,
        'global_name': null,
        'id': '1536790964075495424',
        'username': 'MarlinMammut',
      },
    },
  ],
  'online_count': 2,
  'presences': <dynamic>[],
  'properties': {
    'afk_channel_id': null,
    'afk_timeout': 300,
    'banner': null,
    'banner_height': null,
    'banner_width': null,
    'content_warning_level': 0,
    'content_warning_text': null,
    'default_message_notifications': 0,
    'disabled_operations': 0,
    'embed_splash': null,
    'embed_splash_height': null,
    'embed_splash_width': null,
    'explicit_content_filter': 0,
    'features': ['ANIMATED_ICON', 'ANIMATED_BANNER', 'BANNER', 'INVITE_SPLASH'],
    'icon': null,
    'id': '1536791058510249984',
    'message_history_cutoff': null,
    'mfa_level': 0,
    'name': 'fluxer.dart test server',
    'nsfw': false,
    'nsfw_level': 0,
    'owner_id': '1536790890901667840',
    'rules_channel_id': null,
    'splash': null,
    'splash_card_alignment': 0,
    'splash_height': null,
    'splash_width': null,
    'system_channel_flags': 0,
    'system_channel_id': '1536791058510249987',
    'vanity_url_code': null,
    'verification_level': 0,
  },
  'roles': [
    {
      'color': 0,
      'hoist': false,
      'hoist_position': null,
      'id': '1536791058510249984',
      'mentionable': false,
      'name': '@everyone',
      'permissions': '18014914009747009',
      'position': 0,
    },
    {
      'color': 0,
      'hoist': false,
      'hoist_position': null,
      'id': '1536804370778161152',
      'mentionable': false,
      'name': 'M3 Test Role',
      'permissions': '18014536052624961',
      'position': 4,
    },
    {
      'color': 0,
      'hoist': false,
      'hoist_position': null,
      'id': '1546623715096133632',
      'mentionable': false,
      'name': 'sdk-capture-admin',
      'permissions': '8',
      'position': 3,
    },
  ],
  'stickers': <dynamic>[],
  'threads': <dynamic>[],
  'voice_states': <dynamic>[],
};

const _memberList = {
  'channel_id': '1536791058510249987',
  'groups': [
    {'count': 2, 'id': 'online'},
  ],
  'guild_id': '1536791058510249984',
  'id': '1536791058510249987',
  'member_count': 2,
  'online_count': 2,
  'ops': [
    {
      'items': [
        {
          'group': {'count': 2, 'id': 'online'},
        },
        {
          'member': {
            'accent_color': null,
            'avatar': null,
            'banner': null,
            'communication_disabled_until': null,
            'deaf': false,
            'guild_id': '1536791058510249984',
            'joined_at': '2026-08-12T06:10:10.527Z',
            'mute': false,
            'nick': null,
            'presence': {
              'afk': false,
              'custom_status': null,
              'mobile': false,
              'status': 'online',
              'user': {
                'avatar': null,
                'avatar_color': null,
                'bot': true,
                'discriminator': '9784',
                'flags': 0,
                'global_name': null,
                'id': '1536790964075495424',
                'username': 'MarlinMammut',
              },
            },
            'roles': ['1546623715096133632'],
            'user': {
              'avatar': null,
              'avatar_color': null,
              'bot': true,
              'discriminator': '9784',
              'flags': 0,
              'global_name': null,
              'id': '1536790964075495424',
              'username': 'MarlinMammut',
            },
          },
        },
        {
          'member': {
            'accent_color': null,
            'avatar': null,
            'banner': null,
            'communication_disabled_until': null,
            'deaf': false,
            'joined_at': '2026-08-11T17:39:00.546Z',
            'mute': false,
            'nick': null,
            'presence': {
              'afk': true,
              'custom_status': null,
              'mobile': false,
              'status': 'idle',
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
        },
      ],
      'op': 'SYNC',
      'range': [0, 99],
    },
  ],
};

const _threadMemberList = {
  'guild_id': '1536791058510249984',
  'members': [
    {
      'flags': 0,
      'join_timestamp': '2026-10-20T18:09:37.176Z',
      'member': {
        'accent_color': null,
        'avatar': null,
        'banner': null,
        'communication_disabled_until': null,
        'deaf': false,
        'guild_id': '1536791058510249984',
        'joined_at': '2026-08-12T06:10:10.527Z',
        'mute': false,
        'nick': null,
        'roles': ['1546623715096133632'],
        'user': {
          'avatar': null,
          'avatar_color': null,
          'bot': true,
          'discriminator': '9784',
          'flags': 0,
          'global_name': null,
          'id': '1536790964075495424',
          'username': 'MarlinMammut',
        },
      },
      'presence': {
        'afk': false,
        'custom_status': null,
        'mobile': false,
        'status': 'online',
        'user': {
          'avatar': null,
          'avatar_color': null,
          'bot': true,
          'discriminator': '9784',
          'flags': 0,
          'global_name': null,
          'id': '1536790964075495424',
          'username': 'MarlinMammut',
        },
      },
      'user_id': '1536790964075495424',
    },
  ],
  'thread_id': '1562165912151261184',
};

const _guildCounts = {
  'counts': [
    {'guild_id': '1536791058510249984', 'member_count': 2, 'online_count': 2},
  ],
  'nonce': 'gc-1',
};

const _channelCounts = {
  'counts': [
    {
      'channel_id': '1536791058510249987',
      'guild_id': '1536791058510249984',
      'member_count': 2,
      'online_count': 2,
    },
    {
      'channel_id': '1536791058510249988',
      'guild_id': '1536791058510249984',
      'member_count': 2,
      'online_count': 2,
    },
  ],
  'nonce': 'cc-1',
};

const _forumUnreadsCount = {
  'channel_id': '1562165912516165634',
  'guild_id': '1536791058510249984',
  'threads': [
    {'count': 2, 'thread_id': '1562165912516165636'},
  ],
};

const _forumUnreadsMissing = {
  'channel_id': '1562165912516165634',
  'guild_id': '1536791058510249984',
  'threads': [
    {'missing': true, 'thread_id': '1562165912516165636'},
  ],
};

void main() {
  group('GUILD_CREATE and GUILD_SYNC', () {
    test('GUILD_CREATE carries channels, emojis, stickers and members', () {
      final event =
          GatewayEvent.fromDispatch('GUILD_CREATE', _guildCreate)
              as GuildCreateEvent;

      expect(event.guild.onlineCount, isNotNull);
      expect(event.channels, hasLength(4));
      expect(event.channels.whereType<GuildCategoryChannel>(), hasLength(2));
      expect(event.emojis.single.name, 'recgc');
      expect(event.stickers.single.tags, ['test']);
      expect(event.members.single.user.username, 'MarlinMammut');
      expect(event.voiceStates, isEmpty);
      expect(event.joinedAt, DateTime.parse('2026-08-12T06:10:10.527Z'));
    });

    test('GUILD_SYNC decodes the same guild state', () {
      final event =
          GatewayEvent.fromDispatch('GUILD_SYNC', _guildSync) as GuildSyncEvent;

      expect(event.guild.id, Snowflake.parse('1536791058510249984'));
      expect(event.channels, hasLength(4));
      expect(event.members, hasLength(1));
    });

    test('a member reduced to a bare user id is skipped, not fatal', () {
      // The reference describes this shape for the post-READY burst; it
      // has not been observed.
      final event =
          GatewayEvent.fromDispatch('GUILD_CREATE', {
                ..._guildCreate,
                'members': [
                  {
                    'user': {'id': '5'},
                    'roles': <dynamic>[],
                    'joined_at': '2026-08-12T06:10:10.527Z',
                  },
                  ...(_guildCreate['members']! as List<dynamic>),
                ],
              })
              as GuildCreateEvent;

      expect(event.members, hasLength(1));
      expect(event.channels, hasLength(4));
    });
  });

  group('GUILD_MEMBER_LIST_UPDATE', () {
    test('decodes groups, the SYNC op and members with presences', () {
      final event =
          GatewayEvent.fromDispatch('GUILD_MEMBER_LIST_UPDATE', _memberList)
              as GuildMemberListUpdateEvent;

      expect(event.listId, '1536791058510249987');
      expect(event.channelId, Snowflake.parse('1536791058510249987'));
      expect(event.groups.single.isOnline, isTrue);
      final op = event.ops.single;
      expect(op.isSync, isTrue);
      expect(op.items.first, isA<MemberListGroupItem>());
      final members = op.items.whereType<MemberListMemberItem>().toList();
      expect(members, hasLength(2));
      expect(members.first.presence.status, PresenceStatus.online);
      expect(members.first.presence.user.id, members.first.member.user.id);
    });

    test('an offline member gets its user from the member entry', () {
      // The offline placeholder is from the reference; every member in
      // the recorded list was online.
      final event =
          GatewayEvent.fromDispatch('GUILD_MEMBER_LIST_UPDATE', {
                'guild_id': '1',
                'id': '2',
                'member_count': 1,
                'online_count': 0,
                'groups': [
                  {'id': 'offline', 'count': 1},
                ],
                'ops': [
                  {
                    'op': 'SYNC',
                    'range': [0, 99],
                    'items': [
                      {
                        'member': {
                          'user': {
                            'id': '3',
                            'username': 'away',
                            'discriminator': '0001',
                          },
                          'roles': <dynamic>[],
                          'joined_at': '2026-08-12T06:10:10.527Z',
                          'mute': false,
                          'deaf': false,
                          'presence': {
                            'status': 'offline',
                            'mobile': false,
                            'afk': false,
                          },
                        },
                      },
                    ],
                  },
                ],
              })
              as GuildMemberListUpdateEvent;

      final item = event.ops.single.items.single as MemberListMemberItem;
      expect(item.presence.status, PresenceStatus.offline);
      expect(item.presence.user.username, 'away');
      expect(event.ops.single.end, 99);
    });
  });

  test('THREAD_MEMBER_LIST_UPDATE', () {
    final event =
        GatewayEvent.fromDispatch(
              'THREAD_MEMBER_LIST_UPDATE',
              _threadMemberList,
            )
            as ThreadMemberListUpdateEvent;

    final entry = event.members.single;
    expect(entry.member.userId, Snowflake.parse('1536790964075495424'));
    expect(entry.member.member, isNotNull);
    expect(entry.presence!.status, PresenceStatus.online);
  });

  group('counts', () {
    test('GUILD_COUNTS_UPDATE', () {
      final event =
          GatewayEvent.fromDispatch('GUILD_COUNTS_UPDATE', _guildCounts)
              as GuildCountsUpdateEvent;

      expect(event.nonce, 'gc-1');
      expect(event.counts.single.memberCount, 2);
    });

    test('CHANNEL_MEMBER_COUNTS_UPDATE', () {
      final event =
          GatewayEvent.fromDispatch(
                'CHANNEL_MEMBER_COUNTS_UPDATE',
                _channelCounts,
              )
              as ChannelMemberCountsUpdateEvent;

      expect(event.nonce, 'cc-1');
      expect(event.counts.map((c) => c.channelId), [
        Snowflake.parse('1536791058510249987'),
        Snowflake.parse('1536791058510249988'),
      ]);
    });
  });

  group('FORUM_UNREADS', () {
    test('a count after an acknowledged message', () {
      final event =
          GatewayEvent.fromDispatch('FORUM_UNREADS', _forumUnreadsCount)
              as ForumUnreadsEvent;

      expect(event.threads.single.count, 2);
      expect(event.threads.single.missing, isFalse);
    });

    test('missing without one', () {
      final event =
          GatewayEvent.fromDispatch('FORUM_UNREADS', _forumUnreadsMissing)
              as ForumUnreadsEvent;

      expect(event.threads.single.missing, isTrue);
      expect(event.threads.single.count, isNull);
    });
  });

  test('PRESENCE_UPDATE_BULK applies the batch guild to every entry', () {
    // Shaped from the reference; only sent when a guild recovers.
    final event =
        GatewayEvent.fromDispatch('PRESENCE_UPDATE_BULK', {
              'guild_id': '1',
              'presences': [
                {
                  'user': {'id': '3', 'username': 'u', 'discriminator': '1'},
                  'status': 'idle',
                  'mobile': false,
                  'afk': true,
                  'custom_status': null,
                },
              ],
            })
            as PresenceUpdateBulkEvent;

    expect(event.presences.single.guildId, const Snowflake(1));
    expect(event.presences.single.status, PresenceStatus.idle);
  });

  test('CHANNEL_RECIPIENT_ADD and CHANNEL_RECIPIENT_REMOVE', () {
    // Shaped from the reference: a bot cannot create a group DM without
    // solving a captcha, so neither has been observed.
    final user = {'id': '3', 'username': 'u', 'discriminator': '0001'};
    final added =
        GatewayEvent.fromDispatch('CHANNEL_RECIPIENT_ADD', {
              'channel_id': '9',
              'user': user,
            })
            as ChannelRecipientAddEvent;
    final removed =
        GatewayEvent.fromDispatch('CHANNEL_RECIPIENT_REMOVE', {
              'channel_id': '9',
              'user': user,
            })
            as ChannelRecipientRemoveEvent;

    expect(added.channelId, const Snowflake(9));
    expect(removed.user.username, 'u');
  });

  test('MESSAGE_REACTION_ADD_MANY', () {
    // Shaped from the reference: it needs reactions from another account
    // in a DM with the debounce flag set, not yet observed.
    final event =
        GatewayEvent.fromDispatch('MESSAGE_REACTION_ADD_MANY', {
              'channel_id': '1',
              'message_id': '2',
              'reactions': [
                {
                  'user_id': '3',
                  'emoji': {'name': '👍'},
                },
                {
                  'user_id': '4',
                  'emoji': {'id': '5', 'name': 'party', 'animated': false},
                },
              ],
            })
            as MessageReactionAddManyEvent;

    expect(event.guildId, isNull);
    expect(event.reactions.map((r) => r.userId), [
      const Snowflake(3),
      const Snowflake(4),
    ]);
  });
}
