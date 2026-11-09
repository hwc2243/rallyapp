import 'package:geolocator/geolocator.dart';
import 'package:material_ui/material_ui.dart';

import '../models/discovered_rally.dart';
import '../services/competition_api_client.dart';
import 'select_discovered_route_screen.dart';

class FindRallyScreen extends StatefulWidget {
  const FindRallyScreen({super.key});

  @override
  State<FindRallyScreen> createState() => _FindRallyScreenState();
}

class _FindRallyScreenState extends State<FindRallyScreen> {
  final _apiClient = CompetitionApiClient();
  List<DiscoveredRally>? _rallies;
  String? _error;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _findRallies();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _findRallies() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final position = await _currentPosition();
      final rallies = await _apiClient.discover(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (mounted) setState(() => _rallies = rallies);
    } on _LocationException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to find nearby rallies. Check your connection and try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const _LocationException(
        'Turn on Location Services to find your rally.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const _LocationException(
        'Location access is required to find your rally.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const _LocationException(
        'Location access is disabled. Enable it for RallyMaster Compete in Settings.',
      );
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  void _selectRally(DiscoveredRally rally) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SelectDiscoveredRouteScreen(rally: rally),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Find my rally')),
    body: SafeArea(child: _buildBody()),
  );

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Finding nearby rallies…'),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_outlined, size: 48),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _findRallies,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    final rallies = _rallies;
    if (rallies == null || rallies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_outlined, size: 48),
              const SizedBox(height: 16),
              const Text(
                'No active rallies were found within one mile of your location today.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _findRallies,
                icon: const Icon(Icons.refresh),
                label: const Text('Search again'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rallies.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final rally = rallies[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(rally.name),
            subtitle: Text(rally.date),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectRally(rally),
          ),
        );
      },
    );
  }
}

class _LocationException implements Exception {
  const _LocationException(this.message);
  final String message;
}
