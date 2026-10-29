
import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../models/organization_membership_dto.dart';
import '../network/service_builder_http_client.dart';
import 'tenant_discriminator_provider.dart';

/// Holds OrganizationMembership DTOs and provides its configured external API operations.
class OrganizationMembershipProvider extends ChangeNotifier {
  final ServiceBuilderHttpClient httpClient;
  final TenantDiscriminatorProvider tenantProvider;
  final List<OrganizationMembershipDto> _items = <OrganizationMembershipDto>[];
  bool _isLoading = false;
  Object? _error;

  OrganizationMembershipProvider({
    required this.httpClient,
    required this.tenantProvider,
  }) {
    tenantProvider.addListener(_tenantChanged);
  }

  List<OrganizationMembershipDto> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  Object? get error => _error;
  int? get organizationId =>
      tenantProvider.organizationId;

  Future<OrganizationMembershipDto> create(OrganizationMembershipDto value) async {
    return _execute(() async {
      final response = await httpClient.post(
        _path,
        headers: _headers(),
        body: jsonEncode(value.toJson()),
      );
      httpClient.ensureSuccess(response);
      final created = OrganizationMembershipDto.fromJson(_decodeObject(response));
      _items.add(created);
      notifyListeners();
      return created;
    });
  }

  Future<OrganizationMembershipDto?> get(int serverId) async {
    return _execute(() async {
      final response = await httpClient.get(
        '$_path/$serverId',
        headers: _headers(),
      );
      if (response.statusCode == 404) {
        return null;
      }
      httpClient.ensureSuccess(response);
      return OrganizationMembershipDto.fromJson(_decodeObject(response));
    });
  }

  Future<List<OrganizationMembershipDto>> list() async {
    return _execute(() async {
      final response = await httpClient.get(_path, headers: _headers());
      httpClient.ensureSuccess(response);
      final values = jsonDecode(response.body) as List<dynamic>;
      final result = values
          .map((value) => OrganizationMembershipDto.fromJson(value as Map<String, dynamic>))
          .toList();
      replaceAll(result);
      return result;
    });
  }

  Future<List<OrganizationMembershipDto>> search() async {
    return _execute(() async {
      final response = await httpClient.get(
        '$_path/search',
        headers: _headers(),
      );
      httpClient.ensureSuccess(response);
      final values = jsonDecode(response.body) as List<dynamic>;
      final result = values
          .map((value) => OrganizationMembershipDto.fromJson(value as Map<String, dynamic>))
          .toList();
      replaceAll(result);
      return result;
    });
  }

  Future<OrganizationMembershipDto> update(
    int serverId,
    OrganizationMembershipDto value,
  ) async {
    return _execute(() async {
      final response = await httpClient.put(
        '$_path/$serverId',
        headers: _headers(),
        body: jsonEncode(value.toJson()),
      );
      httpClient.ensureSuccess(response);
      final updated = OrganizationMembershipDto.fromJson(_decodeObject(response));
      final index = _items.indexWhere((item) => item.serverId == updated.serverId);
      if (index >= 0) {
        _items[index] = updated;
      }
      notifyListeners();
      return updated;
    });
  }

  Future<void> delete(int serverId) async {
    await _execute(() async {
      final response = await httpClient.delete(
        '$_path/$serverId',
        headers: _headers(),
      );
      httpClient.ensureSuccess(response);
      _items.removeWhere((item) => item.serverId == serverId);
      notifyListeners();
    });
  }

  void replaceAll(Iterable<OrganizationMembershipDto> values) {
    _items
      ..clear()
      ..addAll(values);
    _error = null;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  Future<T> _execute<T>(Future<T> Function() operation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      return await operation();
    } catch (error) {
      _error = error;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, String> _headers() {
    final headers = <String, String>{};
    final selectedTenant = tenantProvider.organizationId;
    if (selectedTenant == null) {
      throw StateError('A organizationId is required for OrganizationMembership requests');
    }
    headers['organizationId'] = selectedTenant.toString();
    return headers;
  }

  Map<String, dynamic> _decodeObject(dynamic response) =>
      jsonDecode(response.body) as Map<String, dynamic>;

  String get _path => '/api/external/organizationMembership';
  void _tenantChanged() => notifyListeners();

  @override
  void dispose() {
    tenantProvider.removeListener(_tenantChanged);
    super.dispose();
  }
}
