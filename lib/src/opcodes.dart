/// Gateway opcodes, verified against
/// `packages/constants/src/GatewayConstants.ts` (`export const GatewayOpcodes`)
/// in the Fluxer source. Numbered almost identically to Discord's gateway —
/// notably, 13 is unused (reserved/removed) and 5/12/14/15/16 are
/// Fluxer-specific.
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

/// Gateway close codes, verified against
/// `packages/constants/src/GatewayConstants.ts` (`export const GatewayCloseCodes`).
/// 4010/4011/4012 match Discord's shard-related close codes exactly.
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

  /// Whether a client should attempt to reconnect after being closed with
  /// this code. Modeled on Fluxer's client behaviour: auth failures and
  /// version mismatches are terminal, everything else is worth retrying.
  bool get isRecoverable => switch (this) {
    GatewayCloseCode.authenticationFailed => false,
    GatewayCloseCode.invalidApiVersion => false,
    _ => true,
  };
}
