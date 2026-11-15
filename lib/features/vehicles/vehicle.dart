enum VehicleStatus { active, maintenance, inactive }

extension VehicleStatusLabel on VehicleStatus {
  String get label => switch (this) {
    VehicleStatus.active => 'Active',
    VehicleStatus.maintenance => 'In maintenance',
    VehicleStatus.inactive => 'Inactive',
  };
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.vehicleNumber,
    required this.company,
    required this.type,
    required this.brand,
    required this.model,
    required this.status,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'].toString(),
    vehicleNumber: json['vehicleNumber'] as String,
    company: json['company'] as String,
    type: json['type'] as String,
    brand: json['brand'] as String,
    model: json['model'] as String,
    status: json['status'] as String,
  );

  final String id;
  final String vehicleNumber;
  final String company;
  final String type;
  final String brand;
  final String model;
  final String status;

  Vehicle copyWith({
    String? id,
    String? vehicleNumber,
    String? company,
    String? type,
    String? brand,
    String? model,
    String? status,
  }) {
    return Vehicle(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      company: company ?? this.company,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      status: status ?? this.status,
    );
  }

  /// Default mock vehicle data for offline preview and testing
  static const List<Vehicle> mockVehicles = [
    Vehicle(
      id: '1',
      vehicleNumber: 'DHAKA-METRO-GA-11-4821',
      company: 'Stark Logistics Ltd.',
      type: 'Truck',
      brand: 'Volvo',
      model: 'FH16 2023',
      status: 'Active',
    ),
    Vehicle(
      id: '2',
      vehicleNumber: 'DHAKA-METRO-BA-12-9900',
      company: 'Apex Transport',
      type: 'Van',
      brand: 'Toyota',
      model: 'Hiace Super GL',
      status: 'In maintenance',
    ),
    Vehicle(
      id: '3',
      vehicleNumber: 'CHATTOGRAM-GA-04-1290',
      company: 'Stark Logistics Ltd.',
      type: 'Sedan',
      brand: 'Toyota',
      model: 'Corolla Altis',
      status: 'Active',
    ),
    Vehicle(
      id: '4',
      vehicleNumber: 'RAJSHAHI-DA-02-5541',
      company: 'Stark Logistics Ltd.',
      type: 'SUV',
      brand: 'Mitsubishi',
      model: 'Pajero Sport',
      status: 'Inactive',
    ),
    Vehicle(
      id: '5',
      vehicleNumber: 'SYLHET-CHA-01-8822',
      company: 'Express Line',
      type: 'Bus',
      brand: 'Hino',
      model: 'RM2 Deluxe',
      status: 'Active',
    ),
  ];
}

extension VehicleStatusApiValue on VehicleStatus {
  String get apiValue => label;
}
