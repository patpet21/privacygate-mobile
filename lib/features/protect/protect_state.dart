enum ProtectPhase {
  source,
  review,
  protected,
}

enum ProtectOperation {
  idle,
  analyzing,
  verifying,
}

class ProtectState {
  const ProtectState({
    this.phase = ProtectPhase.source,
    this.operation = ProtectOperation.idle,
  });

  final ProtectPhase phase;
  final ProtectOperation operation;

  bool get isBusy => operation != ProtectOperation.idle;
  bool get isAnalyzing => operation == ProtectOperation.analyzing;
  bool get isVerifying => operation == ProtectOperation.verifying;

  ProtectState copyWith({
    ProtectPhase? phase,
    ProtectOperation? operation,
  }) {
    return ProtectState(
      phase: phase ?? this.phase,
      operation: operation ?? this.operation,
    );
  }
}
