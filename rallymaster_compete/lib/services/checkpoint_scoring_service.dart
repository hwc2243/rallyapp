import '../models/checkpoint_crossing.dart';
import '../models/checkpoint_score.dart';
import '../models/competition_route_package.dart';
import '../models/time_allowance.dart';

/// Deterministic, offline calculation for ordinary timed controls.
class CheckpointScoringService {
  const CheckpointScoringService();

  Map<int, CheckpointScore> calculate({
    required CompetitionRoutePackage routePackage,
    required int carNumber,
    required Iterable<CheckpointCrossing> crossings,
    required Iterable<TimeAllowance> allowances,
  }) {
    final crossingByCheckpoint = {
      for (final crossing in crossings) crossing.checkpointId: crossing,
    };
    final allowanceList = allowances.toList(growable: false);
    final carOffsetMillis =
        carNumber *
        (routePackage.carStartIntervalMillis ??
            const Duration(minutes: 1).inMilliseconds);
    final scoringUnit = routePackage.scoringUnit ?? 'SECONDS';
    final maximumScore = routePackage.maximumCheckpointScore;
    final scores = <int, CheckpointScore>{};

    for (final checkpoint in routePackage.checkpoints) {
      if (checkpoint.type != 'TIMED_CONTROL') continue;
      final crossing = crossingByCheckpoint[checkpoint.id];
      final carZeroArrival = checkpoint.carZeroIdealArrivalEpochMillis;
      if (crossing == null || carZeroArrival == null) continue;

      final position = checkpoint.routePosition ?? 0;
      final applicableTaMillis = allowanceList
          .where(
            (allowance) => allowance.effectiveAfterRoutePosition < position,
          )
          .fold<int>(0, (total, allowance) => total + allowance.millis);
      final expectedMillis =
          carZeroArrival + carOffsetMillis + applicableTaMillis;
      final actualMillis = crossing.occurredAt.toUtc().millisecondsSinceEpoch;
      final varianceMillis = actualMillis - expectedMillis;
      final unitMillis = scoringUnit == 'CENTS' ? 600 : 1000;
      var points = varianceMillis.abs() ~/ unitMillis;
      if (maximumScore != null && points > maximumScore) {
        points = maximumScore;
      }

      scores[checkpoint.id] = CheckpointScore(
        checkpointId: checkpoint.id,
        expectedArrival: DateTime.fromMillisecondsSinceEpoch(expectedMillis)
            .toLocal(),
        varianceMillis: varianceMillis,
        points: points,
      );
    }
    return scores;
  }
}
