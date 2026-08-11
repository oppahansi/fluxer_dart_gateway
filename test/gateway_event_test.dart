import 'package:fluxer_gateway/fluxer_gateway.dart';
import 'package:test/test.dart';

void main() {
  group('GatewayEvent.fromDispatch', () {
    test('decodes READY', () {
      final event = GatewayEvent.fromDispatch('READY', {
        'session_id': 'abc123',
        'user': {
          'id': '1',
          'username': 'bot',
          'discriminator': '0',
          'global_name': null,
          'avatar': null,
          'avatar_color': null,
          'bot': true,
          'system': false,
        },
      });

      expect(event, isA<ReadyEvent>());
      final ready = event as ReadyEvent;
      expect(ready.sessionId, 'abc123');
      expect(ready.user.username, 'bot');
    });

    test('decodes RESUMED', () {
      expect(
        GatewayEvent.fromDispatch('RESUMED', const {}),
        isA<ResumedEvent>(),
      );
    });

    test('decodes MESSAGE_CREATE', () {
      final event = GatewayEvent.fromDispatch('MESSAGE_CREATE', {
        'id': '1',
        'channel_id': '2',
        'author': {
          'id': '3',
          'username': 'oppa',
          'discriminator': '0',
          'global_name': null,
          'avatar': null,
          'avatar_color': null,
          'bot': false,
          'system': false,
        },
        'type': 0,
        'flags': 0,
        'content': 'hi',
        'timestamp': '2026-08-11T12:00:00.000Z',
        'edited_timestamp': null,
        'pinned': false,
        'mention_everyone': false,
        'tts': false,
        'mentions': <dynamic>[],
        'mention_roles': <dynamic>[],
      });

      expect(event, isA<MessageCreateEvent>());
      expect((event as MessageCreateEvent).message.content, 'hi');
    });

    test('decodes GUILD_CREATE', () {
      final event = GatewayEvent.fromDispatch('GUILD_CREATE', {
        'id': '1',
        'name': 'Test',
        'icon': null,
        'owner_id': '2',
        'member_count': 1,
      });

      expect(event, isA<GuildCreateEvent>());
      expect((event as GuildCreateEvent).guild.name, 'Test');
    });

    test('falls back to UnknownDispatchEvent for unmodeled event names', () {
      final event = GatewayEvent.fromDispatch('TYPING_START', {
        'channel_id': '1',
      });

      expect(event, isA<UnknownDispatchEvent>());
      final unknown = event as UnknownDispatchEvent;
      expect(unknown.eventName, 'TYPING_START');
      expect(unknown.data, {'channel_id': '1'});
    });
  });
}
