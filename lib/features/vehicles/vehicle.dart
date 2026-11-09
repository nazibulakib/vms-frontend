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
}

extension VehicleStatusApiValue on VehicleStatus {
  String get apiValue => label;
}
