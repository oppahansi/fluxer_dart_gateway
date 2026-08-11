import 'opcodes.dart';

/// The gateway connection's lifecycle, as an explicit sealed state machine.
///
/// This is deliberately not how Fluxer's own reference client tracks
/// connection state (scattered nullable fields and booleans like
/// `shouldReconnectImmediately`) — a real, exhaustively-`switch`-able state
/// machine is the single highest-leverage maintainability choice in this
/// package, since gateway reconnect logic is exactly where ad hoc state
/// tends to rot first.
///
/// Valid transitions:
/// ```
/// Disconnected -> Connecting
/// Connecting -> Identifying | Resuming | Closed
/// Identifying -> Connected | Closed
/// Resuming -> Connected | Closed (falls back to Identifying on INVALID_SESSION)
/// Connected -> Reconnecting | Closed
/// Reconnecting -> Connecting
/// Closed -> Connecting (if GatewayCloseCode.isRecoverable) | Disconnected
/// ```
sealed class GatewayConnectionState {
  const GatewayConnectionState();
}

/// No connection attempt is in progress or established.
final class Disconnected extends GatewayConnectionState {
  const Disconnected();

  @override
  String toString() => 'Disconnected';
}

/// The WebSocket handshake is in flight, waiting for HELLO.
final class Connecting extends GatewayConnectionState {
  const Connecting();

  @override
  String toString() => 'Connecting';
}

/// HELLO received, IDENTIFY sent, waiting for the first READY.
final class Identifying extends GatewayConnectionState {
  const Identifying();

  @override
  String toString() => 'Identifying';
}

/// HELLO received, RESUME sent for an existing session, waiting for
/// RESUMED (or INVALID_SESSION, which falls back to [Identifying]).
final class Resuming extends GatewayConnectionState {
  const Resuming({required this.sessionId});

  final String sessionId;

  @override
  String toString() => 'Resuming(session: $sessionId)';
}

/// Fully connected: READY or RESUMED has been received, heartbeats are
/// flowing, dispatch events are being delivered.
final class Connected extends GatewayConnectionState {
  const Connected({required this.sessionId});

  final String sessionId;

  @override
  String toString() => 'Connected(session: $sessionId)';
}

/// The connection dropped and a reconnect attempt is scheduled or in
/// flight. Distinct from [Connecting] so callers can tell "first connect"
/// apart from "recovering from a drop" (e.g. for logging/backoff).
final class Reconnecting extends GatewayConnectionState {
  const Reconnecting({required this.attempt});

  final int attempt;

  @override
  String toString() => 'Reconnecting(attempt: $attempt)';
}

/// The connection was closed and no further automatic reconnect will
/// happen (either the close code was unrecoverable, or the caller
/// explicitly disconnected).
final class Closed extends GatewayConnectionState {
  const Closed({this.closeCode, this.reason});

  final GatewayCloseCode? closeCode;
  final String? reason;

  @override
  String toString() =>
      'Closed(${closeCode?.name ?? 'no code'}${reason != null ? ': $reason' : ''})';
}
