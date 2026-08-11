/// Abstracts the raw WebSocket so [GatewayConnection][] doesn't depend on
/// `package:web_socket_channel` directly (Adapter pattern) — this is what
/// lets tests drive the connection state machine with a fake, in-memory
/// transport instead of a real socket.
///
/// [GatewayConnection]: package:fluxer_gateway/src/gateway_connection.dart
abstract interface class GatewayTransport {
  /// Text frames received from the server, in order. The stream is done
  /// once the connection closes, at which point [closeCode]/[closeReason]
  /// become meaningful.
  Stream<String> get messages;

  void send(String message);

  Future<void> close({int? code, String? reason});

  /// Valid once [messages] has finished (either the server closed the
  /// connection, or [close] was called).
  int? get closeCode;
  String? get closeReason;
}
