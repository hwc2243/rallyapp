class ServiceBuilderHttpException implements Exception {
  final int statusCode;
  final String message;
  final String? responseBody;

  const ServiceBuilderHttpException(
    this.statusCode,
    this.message, {
    this.responseBody,
  });

  @override
  String toString() => 'ServiceBuilderHttpException($statusCode): $message';
}
