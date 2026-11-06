import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rallymaster_app/providers/external_api_client.dart';

void main() {
  test('injects the bearer token and selected organization id', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(
        request.url.toString(),
        'https://api.example.com/api/external/rally',
      );
      expect(request.headers['authorization'], 'Bearer access-token');
      expect(request.headers['organizationid'], '42');
      return http.Response('[]', 200);
    });
    final apiClient = ExternalApiClient(
      accessToken: () async => 'access-token',
      organizationId: () => 42,
      apiBaseUri: Uri.parse('https://api.example.com'),
      client: client,
    );

    await apiClient.get('/api/external/rally');
  });
}
