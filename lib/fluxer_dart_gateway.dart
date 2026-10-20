/// WebSocket gateway client for the fluxer_dart ecosystem: an explicit
/// connection state machine, heartbeat management, and typed dispatch
/// events.
library;

export 'src/connection_state.dart';
export 'src/gateway_connection.dart';
export 'src/gateway_event.dart';
export 'src/gateway_shard_manager.dart';
export 'src/guild_subscription.dart';
export 'src/gateway_transport.dart';
export 'src/heartbeat_manager.dart';
export 'src/member_list.dart';
export 'src/opcodes.dart';
export 'src/session_flags.dart';
export 'src/web_socket_gateway_transport.dart';
