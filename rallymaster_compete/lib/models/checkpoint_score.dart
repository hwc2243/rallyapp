class CheckpointScore {
  const CheckpointScore({
    required this.checkpointId,
    required this.expectedArrival,
    required this.varianceMillis,
    required this.points,
  });

  final int checkpointId;
  final DateTime expectedArrival;
  final int varianceMillis;
  final int points;
}
