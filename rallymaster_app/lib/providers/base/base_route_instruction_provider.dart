
import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../../models/route_instruction_dto.dart';
import '../../network/service_builder_http_client.dart';

/// Holds RouteInstruction DTOs and provides its configured external API operations.
class BaseRouteInstructionProvider extends ChangeNotifier {
  final ServiceBuilderHttpClient httpClient;
  final List<RouteInstructionDto> _items = <RouteInstructionDto>[];
  bool _isLoading = false;
  Object? _error;

  BaseRouteInstructionProvider({
    required this.httpClient,
  }) {
  }

  List<RouteInstructionDto> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  Object? get error => _error;

  Future<RouteInstructionDto> create(RouteInstructionDto value) async {
    return execute(() async {
      final response = await httpClient.post(
        resourcePath,
        headers: requestHeaders,
        body: jsonEncode(value.toJson()),
      );
      httpClient.ensureSuccess(response);
      final created = RouteInstructionDto.fromJson(decodeObject(response));
      _items.add(created);
      notifyListeners();
      return created;
    });
  }

  Future<RouteInstructionDto?> get(int serverId) async {
    return execute(() async {
      final response = await httpClient.get(
        '$resourcePath/$serverId',
        headers: requestHeaders,
      );
      if (response.statusCode == 404) {
        return null;
      }
      httpClient.ensureSuccess(response);
      return RouteInstructionDto.fromJson(decodeObject(response));
    });
  }

  Future<List<RouteInstructionDto>> list() async {
    return execute(() async {
      final response = await httpClient.get(resourcePath, headers: requestHeaders);
      httpClient.ensureSuccess(response);
      final values = jsonDecode(response.body) as List<dynamic>;
      final result = values
          .map((value) => RouteInstructionDto.fromJson(value as Map<String, dynamic>))
          .toList();
      replaceAll(result);
      return result;
    });
  }

  Future<List<RouteInstructionDto>> search() async {
    return execute(() async {
      final response = await httpClient.get(
        '$resourcePath/search',
        headers: requestHeaders,
      );
      httpClient.ensureSuccess(response);
      final values = jsonDecode(response.body) as List<dynamic>;
      final result = values
          .map((value) => RouteInstructionDto.fromJson(value as Map<String, dynamic>))
          .toList();
      replaceAll(result);
      return result;
    });
  }

  Future<RouteInstructionDto> update(
    int serverId,
    RouteInstructionDto value,
  ) async {
    return execute(() async {
      final response = await httpClient.put(
        '$resourcePath/$serverId',
        headers: requestHeaders,
        body: jsonEncode(value.toJson()),
      );
      httpClient.ensureSuccess(response);
      final updated = RouteInstructionDto.fromJson(decodeObject(response));
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

  void replaceAll(Iterable<RouteInstructionDto> values) {
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
    return headers;
  }

  Map<String, dynamic> decodeObject(dynamic response) =>
      jsonDecode(response.body) as Map<String, dynamic>;

  String get resourcePath => '/api/external/routeInstruction';
}
