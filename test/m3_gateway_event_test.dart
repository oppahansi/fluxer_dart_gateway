import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_gateway/fluxer_dart_gateway.dart';
import 'package:test/test.dart';

Map<String, dynamic> _sampleUserJson({String id = '1'}) => {
  'id': id,
  'username': 'oppa',
  'discriminator': '0',
  'global_name': null,
  'avatar': null,
  'avatar_color': null,
  'bot': false,
  'system': false,
};

Map<String, dynamic> _sampleMemberJson({String userId = '1'}) => {
  'user': _sampleUserJson(id: userId),
  'nick': null,
  'avatar': null,
  'roles': <dynamic>[],
  'joined_at': '2026-08-11T12:00:00.000Z',
  'mute': false,
  'deaf': false,
  'communication_disabled_until': null,
};

Map<String, dynamic> _sampleRoleJson() => {
  'id': '10',
  'name': 'Mods',
  'color': 0,
  'position': 1,
  'permissions': '0',
  'hoist': false,
  'mentionable': false,
  'unicode_emoji': null,
};

void main() {
  group('M3 message events', () {
    test(
      'MESSAGE_UPDATE decodes id/channel_id without requiring a full message',
      () {
        final event = GatewayEvent.fromDispatch('MESSAGE_UPDATE', {
          'id': '1',
          'channel_id': '2',
          'content': 'edited',
        });
        expect(event, isA<MessageUpdateEvent>());
        final update = event as MessageUpdateEvent;
        expect(update.messageId, Snowflake.parse('1'));
        expect(update.channelId, Snowflake.parse('2'));
        expect(update.data['content'], 'edited');
      },
    );

    test('MESSAGE_UPDATE tolerates a missing channel_id', () {
      final event =
          GatewayEvent.fromDispatch('MESSAGE_UPDATE', {'id': '1'})
              as MessageUpdateEvent;
      expect(event.channelId, isNull);
    });

    test('MESSAGE_DELETE decodes', () {
      final event =
          GatewayEvent.fromDispatch('MESSAGE_DELETE', {
                'id': '1',
                'channel_id': '2',
              })
              as MessageDeleteEvent;
      expect(event.messageId, Snowflake.parse('1'));
      expect(event.channelId, Snowflake.parse('2'));
    });

    test('MESSAGE_REACTION_ADD decodes a custom emoji reaction', () {
      final event =
          GatewayEvent.fromDispatch('MESSAGE_REACTION_ADD', {
                'user_id': '1',
                'channel_id': '2',
                'message_id': '3',
                'emoji': {'id': '9', 'name': 'blob'},
                'guild_id': '4',
              })
              as MessageReactionAddEvent;
      expect(event.emoji.isCustom, isTrue);
      expect(event.guildId, Snowflake.parse('4'));
    });

    test(
      'MESSAGE_REACTION_REMOVE decodes a Unicode emoji reaction with no guild (DM)',
      () {
        final event =
            GatewayEvent.fromDispatch('MESSAGE_REACTION_REMOVE', {
                  'user_id': '1',
                  'channel_id': '2',
                  'message_id': '3',
                  'emoji': {'id': null, 'name': '👍'},
                })
                as MessageReactionRemoveEvent;
        expect(event.emoji.isCustom, isFalse);
        expect(event.guildId, isNull);
      },
    );

    test('TYPING_START decodes the unix-seconds timestamp', () {
      final event =
          GatewayEvent.fromDispatch('TYPING_START', {
                'channel_id': '1',
                'user_id': '2',
                'timestamp': 1700000000,
              })
              as TypingStartEvent;
      expect(
        event.timestamp,
        DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
      );
    });
  });

  group('M3 guild events', () {
    test('GUILD_UPDATE decodes a flat Guild (unlike GUILD_CREATE)', () {
      final event =
          GatewayEvent.fromDispatch('GUILD_UPDATE', {
                'id': '1',
                'name': 'Test',
                'icon': null,
                'owner_id': '2',
                'roles': <dynamic>[],
              })
              as GuildUpdateEvent;
      expect(event.guild.name, 'Test');
    });

    test('GUILD_DELETE decodes a minimal id/unavailable-only payload', () {
      final event =
          GatewayEvent.fromDispatch('GUILD_DELETE', {
                'id': '1',
                'unavailable': true,
              })
              as GuildDeleteEvent;
      expect(event.guildId, Snowflake.parse('1'));
      expect(event.unavailable, isTrue);
    });

    test('GUILD_ROLE_CREATE decodes the nested role', () {
      final event =
          GatewayEvent.fromDispatch('GUILD_ROLE_CREATE', {
                'guild_id': '1',
                'role': _sampleRoleJson(),
              })
              as GuildRoleCreateEvent;
      expect(event.guildId, Snowflake.parse('1'));
      expect(event.role.name, 'Mods');
    });

    test('GUILD_ROLE_UPDATE decodes the nested role', () {
      final event =
          GatewayEvent.fromDispatch('GUILD_ROLE_UPDATE', {
                'guild_id': '1',
                'role': _sampleRoleJson(),
              })
              as GuildRoleUpdateEvent;
      expect(event.role.name, 'Mods');
    });

    test('GUILD_ROLE_DELETE decodes just the IDs', () {
      final event =
          GatewayEvent.fromDispatch('GUILD_ROLE_DELETE', {
                'guild_id': '1',
                'role_id': '10',
              })
              as GuildRoleDeleteEvent;
      expect(event.roleId, Snowflake.parse('10'));
    });

    test('GUILD_MEMBER_ADD decodes the flat member+guild_id shape', () {
      final json = _sampleMemberJson()..['guild_id'] = '1';
      final event =
          GatewayEvent.fromDispatch('GUILD_MEMBER_ADD', json)
              as GuildMemberAddEvent;
      expect(event.guildId, Snowflake.parse('1'));
      expect(event.member.user.username, 'oppa');
    });

    test('GUILD_MEMBER_UPDATE decodes the flat member+guild_id shape', () {
      final json = _sampleMemberJson()..['guild_id'] = '1';
      final event =
          GatewayEvent.fromDispatch('GUILD_MEMBER_UPDATE', json)
              as GuildMemberUpdateEvent;
      expect(event.member.user.username, 'oppa');
    });

    test('GUILD_MEMBER_REMOVE decodes just guild_id+user.id — confirmed live '
        'that user carries no other fields, despite what GuildMemberRemove.ts '
        'implies', () {
      final event =
          GatewayEvent.fromDispatch('GUILD_MEMBER_REMOVE', {
                'guild_id': '1',
                'user': {'id': '2'},
              })
              as GuildMemberRemoveEvent;
      expect(event.userId, Snowflake.parse('2'));
    });

    test('GUILD_BAN_ADD decodes guild_id+user.id only, not the full GuildBan '
        'REST shape nor a full User', () {
      final event =
          GatewayEvent.fromDispatch('GUILD_BAN_ADD', {
                'guild_id': '1',
                'user': {'id': '2'},
              })
              as GuildBanAddEvent;
      expect(event.userId, Snowflake.parse('2'));
    });

    test('GUILD_BAN_REMOVE decodes guild_id+user.id', () {
      final event =
          GatewayEvent.fromDispatch('GUILD_BAN_REMOVE', {
                'guild_id': '1',
                'user': {'id': '2'},
              })
              as GuildBanRemoveEvent;
      expect(event.guildId, Snowflake.parse('1'));
      expect(event.userId, Snowflake.parse('2'));
    });
  });

  group('M3 channel events', () {
    test('CHANNEL_CREATE decodes a full Channel', () {
      final event =
          GatewayEvent.fromDispatch('CHANNEL_CREATE', {
                'id': '1',
                'type': 0,
                'name': 'general',
                'guild_id': '2',
                'position': 0,
              })
              as ChannelCreateEvent;
      expect(event.channel, isA<GuildTextChannel>());
    });

    test('CHANNEL_UPDATE carries only id/type plus raw partial data', () {
      final event =
          GatewayEvent.fromDispatch('CHANNEL_UPDATE', {
                'id': '1',
                'type': 0,
                'topic': 'new topic',
              })
              as ChannelUpdateEvent;
      expect(event.channelId, Snowflake.parse('1'));
      expect(event.channelType, ChannelType.guildText);
      expect(event.data['topic'], 'new topic');
    });

    test(
      'CHANNEL_DELETE carries only id/type/guild_id, not a full Channel',
      () {
        final event =
            GatewayEvent.fromDispatch('CHANNEL_DELETE', {
                  'id': '1',
                  'type': 2,
                  'guild_id': '2',
                })
                as ChannelDeleteEvent;
        expect(event.channelType, ChannelType.guildVoice);
        expect(event.guildId, Snowflake.parse('2'));
      },
    );

    test('CHANNEL_DELETE tolerates a missing guild_id (DM channel)', () {
      final event =
          GatewayEvent.fromDispatch('CHANNEL_DELETE', {'id': '1', 'type': 1})
              as ChannelDeleteEvent;
      expect(event.guildId, isNull);
    });
  });
}
