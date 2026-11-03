import 'package:flutter/material.dart';

import '../models/app_session.dart';
import '../models/rally_dto.dart';
import '../models/route_dto.dart';
import '../network/service_builder_http_client.dart';
import '../providers/external_api_client.dart';
import '../providers/route_provider.dart';
import '../providers/tenant_discriminator_provider.dart';

class CreateRouteScreen extends StatefulWidget {
  const CreateRouteScreen({
    super.key,
    required this.session,
    required this.rally,
    required this.accessToken,
  });

  final AppSession session;
  final RallyDto rally;
  final Future<String> Function() accessToken;

  @override
  State<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends State<CreateRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final rallyId = widget.rally.serverId;
    if (rallyId == null) {
      setState(() => _error = 'The selected rally has no server id.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    ServiceBuilderHttpClient? httpClient;
    TenantDiscriminatorProvider? tenantProvider;
    RouteProvider? provider;
    try {
      tenantProvider = TenantDiscriminatorProvider()
        ..setOrganizationId(widget.session.organizationId);
      httpClient = ServiceBuilderHttpClient(
        baseUrl: ExternalApiClient.defaultApiBaseUrl,
        headersProvider: () async => {
          'Authorization': 'Bearer ${await widget.accessToken()}',
        },
      );
      provider = RouteProvider(
        httpClient: httpClient,
        tenantProvider: tenantProvider,
      );
      final route = await provider.create(
        RouteDto(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          rallyId: rallyId,
        ).forOrganizationId(widget.session.organizationId),
      );
      if (mounted) Navigator.of(context).pop(route);
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to create route: $error');
    } finally {
      provider?.dispose();
      tenantProvider?.dispose();
      httpClient?.client.close();
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('New route')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Route name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a route name.'
                      : null,
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 5,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(_saving ? 'Creating…' : 'Create route'),
                ),
              ],
            ),
          ),
        ),
      );
}
