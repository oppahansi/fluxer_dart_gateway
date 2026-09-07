import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_gateway/fluxer_dart_gateway.dart';
import 'package:test/test.dart';

/// Payloads in this file are recorded from a live gateway session rather
/// than written from the reference documentation, because several of
/// these events differ from the shape their REST counterpart would
/// suggest.
void main() {
  group('MESSAGE_DELETE_BULK', () {
    test('reads the id list from ids, not message_ids', () {
      final event =
          GatewayEvent.fromDispatch('MESSAGE_DELETE_BULK', {
                'channel_id': '1546623781735235586',
                'guild_id': '1536791058510249984',
                'ids': ['1546623784633499648', '1546623784910323712'],
              })
              as MessageDeleteBulkEvent;

      expect(event.messageIds, [
        Snowflake.parse('1546623784633499648'),
        Snowflake.parse('1546623784910323712'),
      ]);
      expect(event.channelId, Snowflake.parse('1546623781735235586'));
      expect(event.guildId, Snowflake.parse('1536791058510249984'));
    });

    test('guildId is null for a DM', () {
      final event =
          GatewayEvent.fromDispatch('MESSAGE_DELETE_BULK', {
                'channel_id': '1',
                'ids': ['2'],
              })
              as MessageDeleteBulkEvent;

      expect(event.guildId, isNull);
    });
  });

  group('reaction clearing', () {
    test('MESSAGE_REACTION_REMOVE_ALL carries no emoji', () {
      final event =
          GatewayEvent.fromDispatch('MESSAGE_REACTION_REMOVE_ALL', {
                'channel_id': '1536791058510249987',
                'guild_id': '1536791058510249984',
                'message_id': '1546623781382914048',
              })
              as MessageReactionRemoveAllEvent;

      expect(event.messageId, Snowflake.parse('1546623781382914048'));
    });

    test('MESSAGE_REACTION_REMOVE_EMOJI decodes a unicode emoji', () {
      final event =
          GatewayEvent.fromDispatch('MESSAGE_REACTION_REMOVE_EMOJI', {
                'channel_id': '1536791058510249987',
                'emoji': {'name': '🎉'},
                'guild_id': '1536791058510249984',
                'message_id': '1546623549517594624',
              })
              as MessageReactionRemoveEmojiEvent;

      expect(event.emoji.name, '🎉');
      expect(event.emoji.isCustom, isFalse);
    });
  });

  group('CHANNEL_PINS_UPDATE', () {
    test('decodes the last pin timestamp', () {
      final event =
          GatewayEvent.fromDispatch('CHANNEL_PINS_UPDATE', {
                'channel_id': '1536791058510249987',
                'guild_id': '1536791058510249984',
                'last_pin_timestamp': '2026-09-07T20:50:44.426Z',
              })
              as ChannelPinsUpdateEvent;

      expect(event.lastPinTimestamp, DateTime.utc(2026, 9, 7, 20, 50, 44, 426));
    });

    test('lastPinTimestamp is null once the last pin is removed', () {
      final event =
          GatewayEvent.fromDispatch('CHANNEL_PINS_UPDATE', {
                'channel_id': '1',
                'last_pin_timestamp': null,
              })
              as ChannelPinsUpdateEvent;

      expect(event.lastPinTimestamp, isNull);
    });
  });

  test('WEBHOOKS_UPDATE carries only the channel and guild', () {
    final event =
        GatewayEvent.fromDispatch('WEBHOOKS_UPDATE', {
              'channel_id': '1546623781735235586',
              'guild_id': '1536791058510249984',
            })
            as WebhooksUpdateEvent;

    expect(event.channelId, Snowflake.parse('1546623781735235586'));
    expect(event.guildId, Snowflake.parse('1536791058510249984'));
  });

  test('GUILD_EMOJIS_UPDATE carries the full resulting collection', () {
    final event =
        GatewayEvent.fromDispatch('GUILD_EMOJIS_UPDATE', {
              'guild_id': '1536791058510249984',
              'emojis': [
                {
                  'animated': false,
                  'id': '1546623917483884544',
                  'name': 'sdkcap',
                  'nsfw': false,
                },
              ],
            })
            as GuildEmojisUpdateEvent;

    expect(event.emojis, hasLength(1));
    expect(event.emojis.single.name, 'sdkcap');
  });

  test('GUILD_AUDIT_LOG_ENTRY_CREATE exposes guild, entry and changes', () {
    final event =
        GatewayEvent.fromDispatch('GUILD_AUDIT_LOG_ENTRY_CREATE', {
              'action_type': 25,
              'changes': [
                {
                  'key': 'roles',
                  'new_value': ['1546623715096133632'],
                  'old_value': <dynamic>[],
                },
              ],
              'guild_id': '1536791058510249984',
              'id': '1546623715096133634',
              'options': {'action': 'add', 'role_id': '1546623715096133632'},
              'target_id': '1536790964075495424',
              'user_id': '1536790890901667840',
            })
            as GuildAuditLogEntryCreateEvent;

    expect(event.guildId, Snowflake.parse('1536791058510249984'));
    expect(event.entry.actionType, 25);
    expect(event.entry.userId, Snowflake.parse('1536790890901667840'));
    expect(event.changes.single['key'], 'roles');
  });

  group('SESSIONS_REPLACE', () {
    // The payload is a bare array. Decoding it as an object throws, which
    // took down the whole connection handler before this was modelled.
    const payload = [
      {'afk': false, 'mobile': false, 'session_id': 'all', 'status': 'online'},
      {
        'afk': false,
        'mobile': false,
        'session_id': 'E8DA0B0E3CD93BC540B1AB17B95AE130',
        'status': 'online',
      },
      {
        'afk': false,
        'mobile': false,
        'session_id': '73FBF246A9FE35BFB630D794524D84F8',
        'status': 'offline',
      },
    ];

    test('decodes an array payload', () {
      final event =
          GatewayEvent.fromDispatch('SESSIONS_REPLACE', payload)
              as SessionsReplaceEvent;

      expect(event.sessions, hasLength(3));
      expect(event.connections, hasLength(2));
      expect(event.aggregate?.sessionId, 'all');
      expect(event.aggregate?.status, PresenceStatus.online);
    });

    test('an unmodelled array payload does not throw', () {
      final event = GatewayEvent.fromDispatch('SOME_FUTURE_EVENT', [1, 2, 3]);

      expect(event, isA<UnknownDispatchEvent>());
      expect((event as UnknownDispatchEvent).data, [1, 2, 3]);
    });

    test('a null payload does not throw', () {
      expect(
        GatewayEvent.fromDispatch('SOME_FUTURE_EVENT', null),
        isA<UnknownDispatchEvent>(),
      );
    });
  });

  group('invites', () {
    test('INVITE_CREATE reads the channel id out of the nested object', () {
      final event =
          GatewayEvent.fromDispatch('INVITE_CREATE', {
                'channel': {
                  'id': '1536791058510249987',
                  'name': 'general',
                  'type': 0,
                },
                'code': 'IDdBppx3',
                'created_at': '2026-09-07T20:51:17.153Z',
                'expires_at': '2026-09-07T21:01:17.153Z',
                'guild_id': '1536791058510249984',
                'inviter': {
                  'avatar': null,
                  'avatar_color': null,
                  'bot': true,
                  'discriminator': '9784',
                  'flags': 0,
                  'global_name': null,
                  'id': '1536790964075495424',
                  'username': 'MarlinMammut',
                },
                'max_age': 600,
                'max_uses': 0,
              })
              as InviteCreateEvent;

      expect(event.code, 'IDdBppx3');
      expect(event.channelId, Snowflake.parse('1536791058510249987'));
      expect(event.inviter?.username, 'MarlinMammut');
      expect(event.maxAge, 600);
      expect(event.maxUses, 0);
    });

    test('INVITE_DELETE carries a flat channel_id', () {
      final event =
          GatewayEvent.fromDispatch('INVITE_DELETE', {
                'channel_id': '1536791058510249987',
                'code': 'IDdBppx3',
                'guild_id': '1536791058510249984',
              })
              as InviteDeleteEvent;

      expect(event.code, 'IDdBppx3');
      expect(event.channelId, Snowflake.parse('1536791058510249987'));
    });
  });
}
