import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/competition_checkpoint.dart';
import '../models/checkpoint_crossing.dart';
import '../models/discovered_rally.dart';

class CompetitionApiClient {
  CompetitionApiClient({http.Client? client})
    : _client = client ?? http.Client();

  static const defaultBaseUrl = String.fromEnvironment(
    'RALLYMASTER_COMPETE_API_BASE_URL',
    defaultValue: 'https://rallymaster.connors.ddns.net',
  );

  final http.Client _client;

  Future<List<DiscoveredRally>> discover({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(defaultBaseUrl)
        .resolve('/api/compete/events/discover')
        .replace(
          queryParameters: {
            'latitude': latitude.toString(),
            'longitude': longitude.toString(),
          },
        );
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw CompetitionApiException(response.statusCode);
    }
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map((value) => DiscoveredRally.fromJson(value as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<DiscoveredRoute>> activeRoutes(int rallyId) async {
    final uri = Uri.parse(defaultBaseUrl)
        .resolve('/api/compete/events/$rallyId/routes');
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw CompetitionApiException(response.statusCode);
    }
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map((value) => DiscoveredRoute.fromJson(value as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<CompetitionAuthentication> authenticate({
    required int rallyId,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse(defaultBaseUrl).resolve('/api/compete/authenticate'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'rallyId': rallyId, 'password': password}),
    );
    if (response.statusCode != 200) {
      throw CompetitionApiException(response.statusCode);
    }
    return CompetitionAuthentication.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<CompetitionRegistration> register({
    required int rallyId,
    required int routeId,
    required String registrationToken,
    required String driverFirstName,
    required String driverLastName,
    required String navigatorFirstName,
    required String navigatorLastName,
    required int carNumber,
    required String deviceId,
  }) async {
    final response = await _client.post(
      Uri.parse(defaultBaseUrl).resolve('/api/compete/registrations'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'rallyId': rallyId,
        'routeId': routeId,
        'registrationToken': registrationToken,
        'driverFirstName': driverFirstName,
        'driverLastName': driverLastName,
        'navigatorFirstName': navigatorFirstName,
        'navigatorLastName': navigatorLastName,
        'carNumber': carNumber,
        'deviceId': deviceId,
      }),
    );
    if (response.statusCode != 201) {
      throw CompetitionApiException(response.statusCode);
    }
    return CompetitionRegistration.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<CompetitionRegistration?> existingRegistration({
    required int routeId,
    required String deviceId,
  }) async {
    final response = await _client.get(
      Uri.parse(defaultBaseUrl)
          .resolve('/api/compete/registrations/routes/$routeId'),
      headers: {
        'Accept': 'application/json',
        'X-Competition-Device-Id': deviceId,
      },
    );
    if (response.statusCode == 404 || response.statusCode == 401) return null;
    if (response.statusCode != 200) {
      throw CompetitionApiException(response.statusCode);
    }
    return CompetitionRegistration.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<CompetitionCheckpoint>> downloadCheckpoints({
    required int routeId,
    required String deviceId,
  }) async {
    final response = await _client.get(
      Uri.parse(defaultBaseUrl)
          .resolve('/api/compete/routes/$routeId/checkpoints'),
      headers: {
        'Accept': 'application/json',
        'X-Competition-Device-Id': deviceId,
      },
    );
    if (response.statusCode != 200) {
      throw CompetitionApiException(response.statusCode);
    }
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map(
          (value) =>
              CompetitionCheckpoint.fromJson(value as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<CompetitionTelemetryUploadResult> uploadTelemetry({
    required int routeId,
    required String deviceId,
    required Iterable<CheckpointCrossing> crossings,
  }) async {
    final response = await _client.post(
      Uri.parse(defaultBaseUrl)
          .resolve('/api/compete/routes/$routeId/telemetry'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Competition-Device-Id': deviceId,
      },
      body: jsonEncode({
        'checkpoints': crossings
            .map(
              (crossing) => {
                'checkpointId': crossing.checkpointId,
                'occurredAt': crossing.occurredAt.toUtc().toIso8601String(),
                'interceptLatitude': crossing.interceptLatitude,
                'interceptLongitude': crossing.interceptLongitude,
                'interceptHeading': crossing.heading,
                'interceptSpeed': crossing.speed,
                'interceptAccuracy': crossing.accuracyMeters,
                'closestDistanceMeters': crossing.closestDistanceMeters,
                'samples': crossing.samples
                    .map((sample) => sample.toJson())
                    .toList(growable: false),
              },
            )
            .toList(growable: false),
      }),
    );
    if (response.statusCode != 201) {
      throw CompetitionApiException(response.statusCode);
    }
    return CompetitionTelemetryUploadResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  void dispose() => _client.close();
}

class CompetitionApiException implements Exception {
  const CompetitionApiException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'Competition API request failed ($statusCode).';
}

class CompetitionAuthentication {
  const CompetitionAuthentication({required this.registrationToken});

  factory CompetitionAuthentication.fromJson(Map<String, dynamic> json) =>
      CompetitionAuthentication(
        registrationToken: json['registrationToken'] as String,
      );

  final String registrationToken;
}

class CompetitionRegistration {
  const CompetitionRegistration({
    required this.entryId,
    required this.carNumber,
  });

  factory CompetitionRegistration.fromJson(Map<String, dynamic> json) =>
      CompetitionRegistration(
        entryId: (json['entryId'] as num).toInt(),
        carNumber: (json['carNumber'] as num).toInt(),
      );

  final int entryId;
  final int carNumber;
}

class CompetitionTelemetryUploadResult {
  const CompetitionTelemetryUploadResult({
    required this.accepted,
    required this.alreadyUploaded,
  });

  factory CompetitionTelemetryUploadResult.fromJson(
    Map<String, dynamic> json,
  ) => CompetitionTelemetryUploadResult(
    accepted: (json['accepted'] as num).toInt(),
    alreadyUploaded: (json['alreadyUploaded'] as num).toInt(),
  );

  final int accepted;
  final int alreadyUploaded;
}
