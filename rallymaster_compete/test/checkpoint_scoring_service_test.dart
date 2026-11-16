import 'package:flutter_test/flutter_test.dart';
import 'package:rallymaster_compete/models/checkpoint_crossing.dart';
import 'package:rallymaster_compete/models/competition_checkpoint.dart';
import 'package:rallymaster_compete/models/competition_route_package.dart';
import 'package:rallymaster_compete/models/time_allowance.dart';
import 'package:rallymaster_compete/services/checkpoint_scoring_service.dart';

void main() {
  const service = CheckpointScoringService();
  final baseTime = DateTime.utc(2026, 1, 1, 12).millisecondsSinceEpoch;

  CompetitionRoutePackage routePackage({
    required String scoringUnit,
    required int maximumScore,
  }) => CompetitionRoutePackage(
    routeId: 1,
    rallyId: 1,
    timingPlanVersion: 1,
    carZeroStartEpochMillis: baseTime,
    timeZone: 'America/New_York',
    distanceUnit: 'MILES',
    scoringUnit: scoringUnit,
    carStartIntervalMillis: const Duration(minutes: 1).inMilliseconds,
    maximumCheckpointScore: maximumScore,
    acquisitionRadiusMeters: 150,
    checkpoints: [
      checkpoint(id: 10, position: 2, arrival: baseTime + 120000),
      checkpoint(id: 11, position: 5, arrival: baseTime + 300000),
    ],
  );

  test('uses car-number spacing and allowances only for future controls', () {
    final scores = service.calculate(
      routePackage: routePackage(scoringUnit: 'SECONDS', maximumScore: 100),
      carNumber: 5,
      crossings: [
        crossing(10, baseTime + 120000 + 300000 + 3900),
        crossing(11, baseTime + 300000 + 300000 + 30000 + 5100),
      ],
      allowances: const [
        TimeAllowance(millis: 30000, effectiveAfterRoutePosition: 2),
      ],
    );

    expect(scores[10]?.points, 3); // 5-minute car spacing, no future TA.
    expect(scores[11]?.points, 5); // Car spacing and the 30-second TA.
  });

  test('scores cents using floor and caps the checkpoint score', () {
    final scores = service.calculate(
      routePackage: routePackage(scoringUnit: 'CENTS', maximumScore: 4),
      carNumber: 0,
      crossings: [crossing(10, baseTime + 120000 + 3599)],
      allowances: const [],
    );

    expect(scores[10]?.points, 4); // floor(3.599 / .6) is 5, capped at 4.
  });
}

CompetitionCheckpoint checkpoint({
  required int id,
  required int position,
  required int arrival,
}) => CompetitionCheckpoint(
  id: id,
  number: id,
  routePosition: position,
  segmentNumber: 1,
  type: 'TIMED_CONTROL',
  name: null,
  latitude: 40,
  longitude: -75,
  heading: null,
  distance: 1,
  notes: null,
  carZeroIdealArrivalEpochMillis: arrival,
);

CheckpointCrossing crossing(int checkpointId, int millis) => CheckpointCrossing(
  checkpointId: checkpointId,
  occurredAt: DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true),
  closestDistanceMeters: 1,
  accuracyMeters: 1,
  heading: 90,
  speed: 10,
  interceptLatitude: 40,
  interceptLongitude: -75,
  samples: const [],
);
