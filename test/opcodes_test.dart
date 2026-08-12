import 'package:fluxer_dart_gateway/fluxer_dart_gateway.dart';
import 'package:test/test.dart';

void main() {
  group('GatewayOpcode', () {
    test('fromValue resolves known opcodes', () {
      expect(GatewayOpcode.fromValue(0), GatewayOpcode.dispatch);
      expect(GatewayOpcode.fromValue(10), GatewayOpcode.hello);
      expect(
        GatewayOpcode.fromValue(16),
        GatewayOpcode.requestChannelMemberCounts,
      );
    });

    test('fromValue returns null for gaps in the numbering (e.g. 13)', () {
      expect(GatewayOpcode.fromValue(13), isNull);
    });

    test('fromValue returns null for values outside the known range', () {
      expect(GatewayOpcode.fromValue(999), isNull);
    });
  });

  group('GatewayCloseCode', () {
    test('fromValue resolves known close codes', () {
      expect(
        GatewayCloseCode.fromValue(4004),
        GatewayCloseCode.authenticationFailed,
      );
      expect(
        GatewayCloseCode.fromValue(4012),
        GatewayCloseCode.invalidApiVersion,
      );
    });

    test('authenticationFailed and invalidApiVersion are unrecoverable', () {
      expect(GatewayCloseCode.authenticationFailed.isRecoverable, isFalse);
      expect(GatewayCloseCode.invalidApiVersion.isRecoverable, isFalse);
    });

    test('everything else is recoverable', () {
      expect(GatewayCloseCode.rateLimited.isRecoverable, isTrue);
      expect(GatewayCloseCode.sessionTimeout.isRecoverable, isTrue);
      expect(GatewayCloseCode.unknownError.isRecoverable, isTrue);
    });
  });
}
