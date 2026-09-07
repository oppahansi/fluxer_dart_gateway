/// Gateway opcodes.
///
/// 13 is unassigned. [voiceServerPing] and [gatewayError] are reserved
/// and never appear on the wire in either direction.
enum GatewayOpcode {
  dispatch(0),
  heartbeat(1),
  identify(2),
  presenceUpdate(3),
  voiceStateUpdate(4),
  voiceServerPing(5),
  resume(6),
  reconnect(7),
  requestGuildMembers(8),
  invalidSession(9),
  hello(10),
  heartbeatAck(11),
  gatewayError(12),
  lazyRequest(14),
  requestGuildCounts(15),
  requestChannelMemberCounts(16);

  const GatewayOpcode(this.value);

  final int value;

  static GatewayOpcode? fromValue(int value) {
    for (final candidate in values) {
      if (candidate.value == value) return candidate;
    }
    return null;
  }
}

/// Gateway close codes.
enum GatewayCloseCode {
  unknownError(4000),
  unknownOpcode(4001),
  decodeError(4002),
  notAuthenticated(4003),
  authenticationFailed(4004),
  alreadyAuthenticated(4005),
  invalidSeq(4007),
  rateLimited(4008),
  sessionTimeout(4009),
  invalidShard(4010),
  shardingRequired(4011),
  invalidApiVersion(4012);

  const GatewayCloseCode(this.value);

  final int value;

  static GatewayCloseCode? fromValue(int value) {
    for (final candidate in values) {
      if (candidate.value == value) return candidate;
    }
    return null;
  }

  /// Whether reconnecting with the same configuration can succeed.
  ///
  /// The codes that return `false` describe a rejected configuration —
  /// bad credentials, an unsupported protocol version, or a shard the
  /// server will not accept — so retrying without changing something
  /// reproduces the same close. Everything else is transient.
  bool get isRecoverable => switch (this) {
    GatewayCloseCode.notAuthenticated => false,
    GatewayCloseCode.authenticationFailed => false,
    GatewayCloseCode.invalidShard => false,
    GatewayCloseCode.shardingRequired => false,
    GatewayCloseCode.invalidApiVersion => false,
    _ => true,
  };

  /// Whether a retained session may be resumed after this close, as
  /// opposed to requiring a fresh IDENTIFY.
  ///
  /// [invalidSeq] means the sequence sent with RESUME was rejected, so
  /// the session has to be rebuilt even though reconnecting is fine.
  bool get canResume => switch (this) {
    GatewayCloseCode.invalidSeq => false,
    GatewayCloseCode.sessionTimeout => false,
    _ => isRecoverable,
  };
}
