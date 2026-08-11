import 'package:web_socket_channel/web_socket_channel.dart';

import 'gateway_transport.dart';

/// [GatewayTransport] backed by a real WebSocket, via the official,
/// cross-platform `package:web_socket_channel`.
final class WebSocketGatewayTransport implements GatewayTransport {
  WebSocketGatewayTransport(this._channel);

  factory WebSocketGatewayTransport.connect(Uri uri) =>
      WebSocketGatewayTransport(WebSocketChannel.connect(uri));

  final WebSocketChannel _channel;

  @override
  Stream<String> get messages => _channel.stream.cast<String>();

  @override
  void send(String message) => _channel.sink.add(message);

  @override
  Future<void> close({int? code, String? reason}) =>
      _channel.sink.close(code, reason);

  @override
  int? get closeCode => _channel.closeCode;

  @override
  String? get closeReason => _channel.closeReason;
}
