import 'package:servis_takip/models/stop_model.dart';

class RouteModel {
  final String id;
  final String serviceId;
  final List<StopModel> stops;
  final DateTime createdAt;
  final double totalDistance; // km
  final int estimatedDuration; // dakika

  RouteModel({
    required this.id,
    required this.serviceId,
    required this.stops,
    required this.createdAt,
    required this.totalDistance,
    required this.estimatedDuration,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] ?? '',
      serviceId: json['serviceId'] ?? '',
      stops: (json['stops'] as List?)
              ?.map((stop) => StopModel.fromJson(stop))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      totalDistance: (json['totalDistance'] ?? 0.0).toDouble(),
      estimatedDuration: json['estimatedDuration'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'stops': stops.map((stop) => stop.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'totalDistance': totalDistance,
      'estimatedDuration': estimatedDuration,
    };
  }

  int get completedStopsCount => stops.where((s) => s.isCompleted).length;
  int get totalStopsCount => stops.length;
  double get routeProgress => 
      totalStopsCount > 0 ? (completedStopsCount / totalStopsCount) * 100 : 0;

  StopModel? get nextStop => stops.firstWhere(
        (s) => !s.isCompleted,
        orElse: () => stops.last,
      );

  RouteModel copyWith({
    String? id,
    String? serviceId,
    List<StopModel>? stops,
    DateTime? createdAt,
    double? totalDistance,
    int? estimatedDuration,
  }) {
    return RouteModel(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      stops: stops ?? this.stops,
      createdAt: createdAt ?? this.createdAt,
      totalDistance: totalDistance ?? this.totalDistance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    );
  }
}
