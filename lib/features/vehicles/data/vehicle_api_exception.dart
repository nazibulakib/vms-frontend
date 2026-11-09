class VehicleApiException implements Exception {
  const VehicleApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
