class VehicleModel {
  final String id;
  final String plateNumber;
  final String brand;
  final String model;
  final int capacity;
  final int year;
  final bool isActive;
  final String? driverId;

  VehicleModel({
    required this.id,
    required this.plateNumber,
    required this.brand,
    required this.model,
    required this.capacity,
    required this.year,
    this.isActive = true,
    this.driverId,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] ?? '',
      plateNumber: json['plateNumber'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      capacity: json['capacity'] ?? 0,
      year: json['year'] ?? 0,
      isActive: json['isActive'] ?? true,
      driverId: json['driverId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plateNumber': plateNumber,
      'brand': brand,
      'model': model,
      'capacity': capacity,
      'year': year,
      'isActive': isActive,
      'driverId': driverId,
    };
  }

  String get displayName => '$brand $model ($plateNumber)';

  VehicleModel copyWith({
    String? id,
    String? plateNumber,
    String? brand,
    String? model,
    int? capacity,
    int? year,
    bool? isActive,
    String? driverId,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      capacity: capacity ?? this.capacity,
      year: year ?? this.year,
      isActive: isActive ?? this.isActive,
      driverId: driverId ?? this.driverId,
    );
  }
}
