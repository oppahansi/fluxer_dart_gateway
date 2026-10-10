/// Session behaviour a client opts into at IDENTIFY.
enum SessionFlag {
  /// Coalesce bursts of reaction additions into
  /// `MESSAGE_REACTION_ADD_MANY` dispatches instead of delivering one
  /// `MESSAGE_REACTION_ADD` per reaction.
  debounceMessageReactions(1 << 1),

  /// Declares that the client can parse thread, forum and media
  /// channels. A user session without it receives none of them and no
  /// thread event. A bot session receives them whether or not it is set.
  channelThreads(1 << 2);

  const SessionFlag(this.bit);

  final int bit;
}

/// A set of [SessionFlag]s, held as the integer bitfield IDENTIFY takes.
extension type const SessionFlags(int value) {
  /// No flags set, the default for a session that does not opt in.
  static const SessionFlags none = SessionFlags(0);

  factory SessionFlags.of(Iterable<SessionFlag> flags) =>
      SessionFlags(flags.fold(0, (bits, flag) => bits | flag.bit));

  bool has(SessionFlag flag) => value & flag.bit == flag.bit;

  SessionFlags operator |(SessionFlag flag) => SessionFlags(value | flag.bit);
}
