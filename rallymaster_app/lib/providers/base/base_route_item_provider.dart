
import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../../models/route_item_dto.dart';
import '../../network/service_builder_http_client.dart';
import '../tenant_discriminator_provider.dart';

/// Holds RouteItem DTOs and provides its configured external API operations.
class BaseRouteItemProvider extends ChangeNotifier {
  final ServiceBuilderHttpClient httpClient;
  final TenantDiscriminatorProvider tenantProvider;
  final List<RouteItemDto> _items = <RouteItemDto>[];
  bool _isLoading = false;
  Object? _error;

  BaseRouteItemProvider({
    required this.httpClient,
    required this.tenantProvider,
  }) {
    tenantProvider.addListener(_tenantChanged);
  }

  List<RouteItemDto> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  Object? get error => _error;
  int? get organizationId =>
      tenantProvider.organizationId;

  Future<RouteItemDto> create(RouteItemDto value) async {
    return execute(() async {
      final response = await httpClient.post(
        resourcePath,
        headers: requestHeaders,
        body: jsonEncode(value.toJson()),
      );
      httpClient.ensureSuccess(response);
      final created = RouteItemDto.fromJson(decodeObject(response));
      _items.add(created);
      notifyListeners();
      return created;
    });
  }

  Future<RouteItemDto?> get(int serverId) async {
    return execute(() async {
      final response = await httpClient.get(
        '$resourcePath/$serverId',
        headers: requestHeaders,
      );
      if (response.statusCode == 404) {
        return null;
      }
      httpClient.ensureSuccess(response);
      return RouteItemDto.fromJson(decodeObject(response));
    });
  }

  Future<List<RouteItemDto>> list() async {
    return execute(() async {
      final response = await httpClient.get(resourcePath, headers: requestHeaders);
      httpClient.ensureSuccess(response);
      final values = jsonDecode(response.body) as List<dynamic>;
      final result = values
          .map((value) => RouteItemDto.fromJson(value as Map<String, dynamic>))
          .toList();
      replaceAll(result);
      return result;
    });
  }

  Future<List<RouteItemDto>> search() async {
    return execute(() async {
      final response = await httpClient.get(
        '$resourcePath/search',
        headers: requestHeaders,
      );
      httpClient.ensureSuccess(response);
      final values = jsonDecode(response.body) as List<dynamic>;
      final result = values
          .map((value) => RouteItemDto.fromJson(value as Map<String, dynamic>))
          .toList();
      replaceAll(result);
      return result;
    });
  }

  Future<RouteItemDto> update(
    int serverId,
    RouteItemDto value,
  ) async {
    return execute(() async {
      final response = await httpClient.put(
        '$resourcePath/$serverId',
        headers: requestHeaders,
        body: jsonEncode(value.toJson()),
      );
      httpClient.ensureSuccess(response);
      final updated = RouteItemDto.fromJson(decodeObject(response));
      final index = _items.indexWhere((item) => item.serverId == updated.serverId);
      if (index >= 0) {
        _items[index] = updated;
      }
      notifyListeners();
      return updated;
    });
  }

  Future<void> delete(int serverId) async {
    await execute(() async {
      final response = await httpClient.delete(
        '$resourcePath/$serverId',
        headers: requestHeaders,
      );
      httpClient.ensureSuccess(response);
      _items.removeWhere((item) => item.serverId == serverId);
      notifyListeners();
    });
  }

  void replaceAll(Iterable<RouteItemDto> values) {
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

  Future<T> execute<T>(Future<T> Function() operation) async {
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

  Map<String, String> get requestHeaders {
    final headers = <String, String>{};
    final selectedTenant = tenantProvider.organizationId;
    if (selectedTenant == null) {
      throw StateError('A organizationId is required for RouteItem requests');
    }
    headers['organizationId'] = selectedTenant.toString();
    return headers;
  }

  Map<String, dynamic> decodeObject(dynamic response) =>
      jsonDecode(response.body) as Map<String, dynamic>;

  String get resourcePath => '/api/external/routeItem';
  void _tenantChanged() => notifyListeners();

  @override
  void dispose() {
    tenantProvider.removeListener(_tenantChanged);
    super.dispose();
  }
}
