import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vms_frontend/core/config/env_config.dart';
import 'package:vms_frontend/features/vehicles/data/vehicle_api_exception.dart';
import 'package:vms_frontend/features/vehicles/vehicle.dart';

class VehicleApiClient {
  VehicleApiClient({
    http.Client? client,
    String? baseUrl,
    this.accessTokenProvider,
  }) : _client = client ?? http.Client(),
       _baseUrl = (baseUrl ?? EnvConfig.apiBaseUrl).replaceFirst(
         RegExp(r'/+$'),
         '',
       );

  final http.Client _client;
  final String? Function()? accessTokenProvider;
  final String _baseUrl;

  Future<List<Vehicle>> listVehicles() async {
    final response = await _send(
      () => _client.get(_vehiclesUri, headers: _headers()),
    );
    final decoded = _decodeResponse(response);
    if (decoded is! List) {
      throw const VehicleApiException(
        'The server returned an invalid vehicle list.',
      );
    }
    return decoded
        .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    final response = await _send(
      () => _client.post(
        _vehiclesUri,
        headers: _headers(json: true),
        body: jsonEncode(_requestBody(vehicle)),
      ),
    );
    return _vehicleFromResponse(response);
  }

  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    final response = await _send(
      () => _client.put(
        _vehicleUri(vehicle.id),
        headers: _headers(json: true),
        body: jsonEncode(_requestBody(vehicle)),
      ),
    );
    return _vehicleFromResponse(response);
  }

  Future<void> deleteVehicle(String id) async {
    final response = await _send(
      () => _client.delete(_vehicleUri(id), headers: _headers()),
    );
    if (response.statusCode != 204) {
      _throwApiError(response);
    }
  }

  Uri get _vehiclesUri => Uri.parse('$_baseUrl/vehicles');

  Uri _vehicleUri(String id) => Uri.parse('$_baseUrl/vehicles/$id');

  Map<String, String> _headers({bool json = false}) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    final token = accessTokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, String> _requestBody(Vehicle vehicle) => {
    'vehicleNumber': vehicle.vehicleNumber,
    'company': vehicle.company,
    'type': vehicle.type,
    'brand': vehicle.brand,
    'model': vehicle.model,
    'status': vehicle.status,
  };

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _throwApiError(response);
      }
      return response;
    } on VehicleApiException {
      rethrow;
    } on TimeoutException {
      throw const VehicleApiException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const VehicleApiException(
        'Could not connect to the server. Check your connection and try again.',
      );
    } on FormatException {
      throw const VehicleApiException(
        'The server returned an invalid response.',
      );
    }
  }

  dynamic _decodeResponse(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const VehicleApiException(
        'The server returned an invalid response.',
      );
    }
  }

  Vehicle _vehicleFromResponse(http.Response response) {
    final decoded = _decodeResponse(response);
    if (decoded is! Map<String, dynamic>) {
      throw const VehicleApiException(
        'The server returned an invalid vehicle.',
      );
    }
    return Vehicle.fromJson(decoded);
  }

  Never _throwApiError(http.Response response) {
    String message = 'The request failed (${response.statusCode}).';
    try {
      final decoded = _decodeResponse(response);
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        message = decoded['message'] as String;
      }
    } on VehicleApiException {
      // Keep the status-based message if the response is not JSON.
    }
    if (response.statusCode == 401) {
      message = 'Your session has expired. Please sign in again.';
    }
    throw VehicleApiException(message, statusCode: response.statusCode);
  }
}
