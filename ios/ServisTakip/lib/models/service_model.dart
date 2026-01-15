import 'package:servis_takip/models/route_model.dart';
import 'package:servis_takip/models/user_model.dart';

enum ServiceStatus {
  pending,
  onRoute,
  arrived,
  completed,
  cancelled,
}

class ServiceModel {
  final String id;
  final String vehicleId;
  final String driverId;
  final UserModel? driver;
  final DateTime scheduledDate;
  final ServiceStatus status;
  final RouteModel? route;
  final int passengerCount;
  final int capacity;
  final DateTime? startedAt;
  final DateTime? completedAt;

  ServiceModel({
    required this.id,
    required this.vehicleId,
    required this.driverId,
    this.driver,
    required this.scheduledDate,
    required this.status,
    this.route,
    required this.passengerCount,
    required this.capacity,
    this.startedAt,
    this.completedAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      vehicleId: json['vehicleId'] ?? '',
      driverId: json['driverId'] ?? '',
      driver: json['driver'] != null ? UserModel.fromJson(json['driver']) : null,
      scheduledDate: DateTime.parse(json['scheduledDate']),
      status: _parseStatus(json['status']),
      route: json['route'] != null ? RouteModel.fromJson(json['route']) : null,
      passengerCount: json['passengerCount'] ?? 0,
      capacity: json['capacity'] ?? 0,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'driverId': driverId,
      'driver': driver?.toJson(),
      'scheduledDate': scheduledDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'route': route?.toJson(),
      'passengerCount': passengerCount,
      'capacity': capacity,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  static ServiceStatus _parseStatus(dynamic status) {
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'onroute':
          return ServiceStatus.onRoute;
        case 'arrived':
          return ServiceStatus.arrived;
        case 'completed':
          return ServiceStatus.completed;
        case 'cancelled':
          return ServiceStatus.cancelled;
        default:
          return ServiceStatus.pending;
      }
    }
    return ServiceStatus.pending;
  }

  String get statusText {
    switch (status) {
      case ServiceStatus.pending:
        return 'Bekliyor';
      case ServiceStatus.onRoute:
        return 'Yolda';
      case ServiceStatus.arrived:
        return 'Geldi';
      case ServiceStatus.completed:
        return 'Tamamlandı';
      case ServiceStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  double get fillRate => capacity > 0 ? (passengerCount / capacity) * 100 : 0;

  ServiceModel copyWith({
    String? id,
    String? vehicleId,
    String? driverId,
    UserModel? driver,
    DateTime? scheduledDate,
    ServiceStatus? status,
    RouteModel? route,
    int? passengerCount,
    int? capacity,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      driver: driver ?? this.driver,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      route: route ?? this.route,
      passengerCount: passengerCount ?? this.passengerCount,
      capacity: capacity ?? this.capacity,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
