import 'package:material_ui/material_ui.dart';

import '../models/discovered_rally.dart';
import '../services/competition_api_client.dart';
import 'registration_screen.dart';

class SelectDiscoveredRouteScreen extends StatefulWidget {
  const SelectDiscoveredRouteScreen({super.key, required this.rally});

  final DiscoveredRally rally;

  @override
  State<SelectDiscoveredRouteScreen> createState() =>
      _SelectDiscoveredRouteScreenState();
}

class _SelectDiscoveredRouteScreenState
    extends State<SelectDiscoveredRouteScreen> {
  final _apiClient = CompetitionApiClient();
  List<DiscoveredRoute>? _routes;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final routes = await _apiClient.activeRoutes(widget.rally.id);
      if (mounted) {
        setState(() => _routes = routes);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load the available routes.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Select route')),
    body: SafeArea(child: _buildBody()),
  );

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: FilledButton.icon(
          onPressed: _loadRoutes,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      );
    }
    final routes = _routes!;
    if (routes.isEmpty) {
      return const Center(child: Text('No active routes are available.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: routes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final route = routes[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.alt_route),
            title: Text(route.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) =>
                    RegistrationScreen(rally: widget.rally, route: route),
              ),
            ),
          ),
        );
      },
    );
  }
}
