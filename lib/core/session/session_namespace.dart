class SessionNamespace {
  const SessionNamespace._();

  static String browserTurn(String sessionId, int turn) {
    if (!RegExp(r'^[0-9a-f]{32}$').hasMatch(sessionId)) {
      throw ArgumentError.value(sessionId, 'sessionId', 'Expected 32 lowercase hex characters');
    }
    if (turn < 1 || turn > 9999) {
      throw ArgumentError.value(turn, 'turn', 'Expected a turn between 1 and 9999');
    }
    return 'B${sessionId.substring(0, 8).toUpperCase()}_T${turn.toString().padLeft(4, '0')}';
  }

  static String applyToBaseToken(String baseToken, String namespace) {
    if (!baseToken.startsWith('[[PG_') || !baseToken.endsWith(']]')) {
      throw ArgumentError.value(baseToken, 'baseToken', 'Expected a PrivacyGate base token');
    }
    return '[[PG_${namespace}_${baseToken.substring(5)}';
  }
}
