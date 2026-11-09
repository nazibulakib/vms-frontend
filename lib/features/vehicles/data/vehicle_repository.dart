import 'package:vms_frontend/features/vehicles/data/vehicle_api_client.dart';
import 'package:vms_frontend/features/vehicles/vehicle.dart';

class VehicleRepository {
  const VehicleRepository(this._apiClient);

  final VehicleApiClient _apiClient;

  Future<List<Vehicle>> listVehicles() => _apiClient.listVehicles();

  Future<Vehicle> createVehicle(Vehicle vehicle) =>
      _apiClient.createVehicle(vehicle);

  Future<Vehicle> updateVehicle(Vehicle vehicle) =>
      _apiClient.updateVehicle(vehicle);

  Future<void> deleteVehicle(String id) => _apiClient.deleteVehicle(id);
}
