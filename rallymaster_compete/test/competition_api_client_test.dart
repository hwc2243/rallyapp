import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rallymaster_compete/services/competition_api_client.dart';

void main() {
  test('decodes the public rally discovery response', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/compete/events/discover');
      expect(request.url.queryParameters['latitude'], '40.0');
      expect(request.url.queryParameters['longitude'], '-75.0');
      return http.Response(
        '[{"rallyId":7,"name":"Fall Rally","date":"2026-11-06"}]',
        200,
      );
    });
    final api = CompetitionApiClient(client: client);

    final rallies = await api.discover(latitude: 40, longitude: -75);

    expect(rallies, hasLength(1));
    expect(rallies.single.id, 7);
    api.dispose();
  });

  test('loads active routes only after a rally is selected', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/compete/events/7/routes');
      return http.Response('[{"routeId":12,"name":"Main Route"}]', 200);
    });
    final api = CompetitionApiClient(client: client);

    final routes = await api.activeRoutes(7);

    expect(routes.single.id, 12);
    expect(routes.single.name, 'Main Route');
    api.dispose();
  });

  test('authenticates then registers a selected team', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/compete/authenticate') {
        expect(request.method, 'POST');
        expect(request.body, contains('event-password'));
        return http.Response('{"registrationToken":"token-123"}', 200);
      }
      expect(request.url.path, '/api/compete/registrations');
      expect(request.method, 'POST');
      expect(request.body, contains('"routeId":12'));
      expect(request.body, contains('"registrationToken":"token-123"'));
      return http.Response('{"entryId":55,"carNumber":9}', 201);
    });
    final api = CompetitionApiClient(client: client);

    final authentication = await api.authenticate(
      rallyId: 7,
      password: 'event-password',
    );
    final registration = await api.register(
      rallyId: 7,
      routeId: 12,
      registrationToken: authentication.registrationToken,
      driverFirstName: 'Driver',
      driverLastName: 'One',
      navigatorFirstName: 'Navigator',
      navigatorLastName: 'One',
      carNumber: 9,
      deviceId: 'device-1',
    );

    expect(registration.entryId, 55);
    expect(registration.carNumber, 9);
    api.dispose();
  });
}
