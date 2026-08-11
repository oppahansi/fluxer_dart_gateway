import 'dart:async';
import 'dart:convert';

import 'package:fluxer_gateway/fluxer_gateway.dart';

/// An in-memory [GatewayTransport] double: tests push server frames via
/// [emit] and inspect what the connection sent via [sentMessages], with no
/// real socket involved. Preferred here over a mocktail `Mock` because the
/// gateway boundary is fundamentally a stateful bidirectional stream
/// protocol, not a handful of call/verify request-response methods —
/// mocktail shines at the latter (see fluxer_rest's tests), a hand-rolled
/// fake fits the former better.
final class FakeGatewayTransport implements GatewayTransport {
  final _incoming = StreamController<String>.broadcast();
  final List<Map<String, dynamic>> sentMessages = [];

  @override
  int? closeCode;

  @override
  String? closeReason;

  bool closedByClient = false;

  @override
  Stream<String> get messages => _incoming.stream;

  @override
  void send(String message) {
    sentMessages.add(jsonDecode(message) as Map<String, dynamic>);
  }

  @override
  Future<void> close({int? code, String? reason}) async {
    closedByClient = true;
    closeCode ??= code;
    closeReason ??= reason;
    await _incoming.close();
  }

  /// Simulates a frame arriving from the server.
  void emit(Map<String, dynamic> payload) {
    _incoming.add(jsonEncode(payload));
  }

  /// Simulates the server dropping the connection with the given close
  /// code, without the client having called [close] itself.
  Future<void> simulateServerClose(int code, [String? reason]) async {
    closeCode = code;
    closeReason = reason;
    await _incoming.close();
  }

  /// Simulates an abrupt network failure: the socket just stops delivering
  /// frames, with no close frame and so no close code at all — unlike
  /// [simulateServerClose], which always has one.
  Future<void> simulateNetworkDrop() async {
    await _incoming.close();
  }
}
