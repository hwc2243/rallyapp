import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/discovered_rally.dart';
import '../services/competition_api_client.dart';
import '../services/competition_device_identity.dart';
import 'downloaded_checkpoints_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({
    super.key,
    required this.rally,
    required this.route,
  });

  final DiscoveredRally rally;
  final DiscoveredRoute route;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  static const _entryIdKey = 'competition_entry_id';
  static const _rallyIdKey = 'competition_rally_id';
  static const _routeIdKey = 'competition_route_id';
  static const _carNumberKey = 'competition_car_number';
  final _formKey = GlobalKey<FormState>();
  final _apiClient = CompetitionApiClient();
  final _driverFirstName = TextEditingController();
  final _driverLastName = TextEditingController();
  final _navigatorFirstName = TextEditingController();
  final _navigatorLastName = TextEditingController();
  final _carNumber = TextEditingController();
  final _password = TextEditingController();
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _apiClient.dispose();
    _driverFirstName.dispose();
    _driverLastName.dispose();
    _navigatorFirstName.dispose();
    _navigatorLastName.dispose();
    _carNumber.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final authentication = await _apiClient.authenticate(
        rallyId: widget.rally.id,
        password: _password.text,
      );
      final registration = await _apiClient.register(
        rallyId: widget.rally.id,
        routeId: widget.route.id,
        registrationToken: authentication.registrationToken,
        driverFirstName: _driverFirstName.text.trim(),
        driverLastName: _driverLastName.text.trim(),
        navigatorFirstName: _navigatorFirstName.text.trim(),
        navigatorLastName: _navigatorLastName.text.trim(),
        carNumber: int.parse(_carNumber.text),
        deviceId: await CompetitionDeviceIdentity.getOrCreate(),
      );
      await _saveRegistration(registration);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Registration complete'),
          content: Text(
            'Car ${registration.carNumber} is registered for ${widget.route.name}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => DownloadedCheckpointsScreen(
              rally: widget.rally,
              route: widget.route,
            ),
          ),
        );
      }
    } on CompetitionApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.statusCode == 401
              ? 'The event password was not accepted.'
              : error.statusCode == 409
              ? 'That car number or this device is already registered for this rally.'
              : 'Unable to register right now. Please try again.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to register right now. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _saveRegistration(CompetitionRegistration registration) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_entryIdKey, registration.entryId);
    await preferences.setInt(_rallyIdKey, widget.rally.id);
    await preferences.setInt(_routeIdKey, widget.route.id);
    await preferences.setInt(_carNumberKey, registration.carNumber);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Register team')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.rally.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              widget.route.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Text('DRIVER', style: Theme.of(context).textTheme.labelLarge),
            _nameField(_driverFirstName, 'First name'),
            _nameField(_driverLastName, 'Last name'),
            const SizedBox(height: 16),
            Text('NAVIGATOR', style: Theme.of(context).textTheme.labelLarge),
            _nameField(_navigatorFirstName, 'First name'),
            _nameField(_navigatorLastName, 'Last name'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _carNumber,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Car number'),
              validator: (value) {
                final carNumber = int.tryParse(value ?? '');
                return carNumber != null && carNumber > 0
                    ? null
                    : 'Enter a positive car number';
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Event password'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter the event password'
                  : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _submitting ? null : _register,
              icon: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.how_to_reg),
              label: Text(_submitting ? 'Registering…' : 'Register team'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _nameField(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: label),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Required' : null,
      );
}
