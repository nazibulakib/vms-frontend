class VehicleApiException implements Exception {
  const VehicleApiException(
    this.message, {
    this.statusCode,
    this.timedOut = false,
  });

  final String message;
  final int? statusCode;
  final bool timedOut;

  @override
  String toString() => message;
}
