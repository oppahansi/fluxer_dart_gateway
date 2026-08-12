import 'package:fluxer_dart_gateway/fluxer_dart_gateway.dart';
import 'package:test/test.dart';

import 'fakes/fake_gateway_transport.dart';

void main() {
  test(
    'connect() appends the mandatory v=1 and encoding=json query params',
    () async {
      Uri? capturedUrl;
      final connection = GatewayConnection(
        gatewayUrl: Uri.parse('wss://gateway.fluxer.app'),
        token: 't',
        transportFactory: (url) {
          capturedUrl = url;
          return FakeGatewayTransport();
        },
      );

      await connection.connect();
      await connection.dispose();

      expect(capturedUrl!.queryParameters['v'], '1');
      expect(capturedUrl!.queryParameters['encoding'], 'json');
    },
  );

  test('preserves any existing query params on gatewayUrl', () async {
    Uri? capturedUrl;
    final connection = GatewayConnection(
      gatewayUrl: Uri.parse('wss://gateway.fluxer.app?shard=0'),
      token: 't',
      transportFactory: (url) {
        capturedUrl = url;
        return FakeGatewayTransport();
      },
    );

    await connection.connect();
    await connection.dispose();

    expect(capturedUrl!.queryParameters['shard'], '0');
    expect(capturedUrl!.queryParameters['v'], '1');
  });
}
