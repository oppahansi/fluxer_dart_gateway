import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_gateway/fluxer_dart_gateway.dart';
import 'package:test/test.dart';

// Recorded from a live bot session: a channel reorder, a role reorder,
// and Request Guild Members with and without presences, nonce and
// matches, plus a full-list request repeated inside its 30 s budget.
const _channelBulk = {
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
      'position': 3,
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
      'position': 5,
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
      'position': 4,
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
      'position': 6,
      'rate_limit_per_user': 0,
      'rtc_p2p': false,
      'rtc_region': null,
      'topic': null,
      'type': 2,
      'user_limit': 0,
      'voice_connection_limit': 5,
    },
    {
      'content_warning_level': 0,
      'content_warning_text': null,
      'guild_id': '1536791058510249984',
      'id': '1562162800980131840',
      'last_message_id': null,
      'last_pin_timestamp': null,
      'name': 'rec-a',
      'nsfw': false,
      'nsfw_override': null,
      'parent_id': null,
      'permission_overwrites': <dynamic>[],
      'position': 2,
      'rate_limit_per_user': 0,
      'topic': null,
      'type': 0,
    },
    {
      'content_warning_level': 0,
      'content_warning_text': null,
      'guild_id': '1536791058510249984',
      'id': '1562162800980131842',
      'last_message_id': null,
      'last_pin_timestamp': null,
      'name': 'rec-b',
      'nsfw': false,
      'nsfw_override': null,
      'parent_id': null,
      'permission_overwrites': <dynamic>[],
      'position': 1,
      'rate_limit_per_user': 0,
      'topic': null,
      'type': 0,
    },
  ],
  'guild_id': '1536791058510249984',
};

const _roleBulk = {
  'guild_id': '1536791058510249984',
  'roles': [
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
    {
      'color': 3368703,
      'hoist': true,
      'hoist_position': null,
      'id': '1562162800980131844',
      'mentionable': true,
      'name': 'rec-r1b',
      'permissions': '18014914009747009',
      'position': 2,
    },
  ],
};

const _chunkPresences = {
  'chunk_count': 1,
  'chunk_index': 0,
  'guild_id': '1536791058510249984',
  'members': [
    {
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
  'nonce': 'full-1',
  'presences': [
    {
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
  ],
};

const _chunkEmpty = {
  'chunk_count': 1,
  'chunk_index': 0,
  'guild_id': '1536791058510249984',
  'members': <dynamic>[],
  'nonce': 'nomatch',
};

const _chunkNoNonce = {
  'chunk_count': 1,
  'chunk_index': 0,
  'guild_id': '1536791058510249984',
  'members': [
    {
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
  ],
};

const _rateLimited = {
  'meta': {'guild_id': '1536791058510249984', 'nonce': 'full-2'},
  'opcode': 8,
  'retry_after': 28.498,
};

void main() {
  group('CHANNEL_UPDATE_BULK', () {
    test('carries every channel of the guild in full', () {
      final event =
          GatewayEvent.fromDispatch('CHANNEL_UPDATE_BULK', _channelBulk)
              as ChannelUpdateBulkEvent;

      expect(event.guildId, Snowflake.parse('1536791058510249984'));
      expect(event.channels, hasLength(6));
      expect(event.channels.whereType<GuildCategoryChannel>(), hasLength(2));
      final moved = event.channels.whereType<GuildTextChannel>().firstWhere(
        (c) => c.name == 'rec-b',
      );
      expect(moved.position, 1);
    });
  });

  group('GUILD_ROLE_UPDATE_BULK', () {
    test('carries the changed roles in full', () {
      final event =
          GatewayEvent.fromDispatch('GUILD_ROLE_UPDATE_BULK', _roleBulk)
              as GuildRoleUpdateBulkEvent;

      expect(event.roles.map((r) => r.name), [
        'M3 Test Role',
        'sdk-capture-admin',
        'rec-r1b',
      ]);
      expect(event.roles.last.position, 2);
      expect(event.roles.last.hoistPosition, isNull);
    });
  });

  group('GUILD_MEMBERS_CHUNK', () {
    test('decodes members, presences and the nonce', () {
      final event =
          GatewayEvent.fromDispatch('GUILD_MEMBERS_CHUNK', _chunkPresences)
              as GuildMembersChunkEvent;

      expect(event.members, hasLength(2));
      expect(event.chunkIndex, 0);
      expect(event.chunkCount, 1);
      expect(event.nonce, 'full-1');
      expect(event.presences.single.status, PresenceStatus.online);
      expect(
        event.presences.single.user.id,
        Snowflake.parse('1536790964075495424'),
      );
    });

    test('a request that matched nobody still produces one chunk', () {
      final event =
          GatewayEvent.fromDispatch('GUILD_MEMBERS_CHUNK', _chunkEmpty)
              as GuildMembersChunkEvent;

      expect(event.members, isEmpty);
      expect(event.presences, isEmpty);
      expect(event.chunkCount, 1);
      expect(event.nonce, 'nomatch');
    });

    test('no nonce is echoed when none was sent', () {
      final event =
          GatewayEvent.fromDispatch('GUILD_MEMBERS_CHUNK', _chunkNoNonce)
              as GuildMembersChunkEvent;

      expect(event.nonce, isNull);
      expect(event.members, hasLength(1));
    });
  });

  group('RATE_LIMITED', () {
    test('decodes a fractional retry_after and the meta', () {
      final event =
          GatewayEvent.fromDispatch('RATE_LIMITED', _rateLimited)
              as RateLimitedEvent;

      expect(event.opcode, 8);
      expect(event.retryAfter, const Duration(milliseconds: 28498));
      expect(event.guildId, Snowflake.parse('1536791058510249984'));
      expect(event.nonce, 'full-2');
    });
  });

  group('USER_UPDATE', () {
    // Not observed: a bot token cannot change its own user record.
    // Shaped from the reference, which sends the private user object.
    test('decodes the user and ignores private-only fields', () {
      final event =
          GatewayEvent.fromDispatch('USER_UPDATE', {
                'id': '1536790964075495424',
                'username': 'MarlinMammut',
                'discriminator': '9784',
                'global_name': 'Marlin',
                'avatar': null,
                'avatar_color': null,
                'bot': true,
                'flags': 0,
                'mfa_enabled': false,
                'verified': true,
              })
              as UserUpdateEvent;

      expect(event.user.globalName, 'Marlin');
      expect(event.user.bot, isTrue);
    });
  });
}
