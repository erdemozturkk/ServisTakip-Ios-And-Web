import 'package:servis_takip/models/user_model.dart';

class StopModel {
  final String id;
  final String routeId;
  final int orderIndex;
  final double latitude;
  final double longitude;
  final String address;
  final List<String> passengerIds;
  final List<UserModel>? passengers;
  final DateTime? estimatedArrival;
  final DateTime? actualArrival;
  final bool isCompleted;

  StopModel({
    required this.id,
    required this.routeId,
    required this.orderIndex,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.passengerIds,
    this.passengers,
    this.estimatedArrival,
    this.actualArrival,
    this.isCompleted = false,
  });

  factory StopModel.fromJson(Map<String, dynamic> json) {
    return StopModel(
      id: json['id'] ?? '',
      routeId: json['routeId'] ?? '',
      orderIndex: json['orderIndex'] ?? 0,
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
      passengerIds: (json['passengerIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      passengers: (json['passengers'] as List?)
          ?.map((p) => UserModel.fromJson(p))
          .toList(),
      estimatedArrival: json['estimatedArrival'] != null
          ? DateTime.parse(json['estimatedArrival'])
          : null,
      actualArrival: json['actualArrival'] != null
          ? DateTime.parse(json['actualArrival'])
          : null,
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeId': routeId,
      'orderIndex': orderIndex,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'passengerIds': passengerIds,
      'passengers': passengers?.map((p) => p.toJson()).toList(),
      'estimatedArrival': estimatedArrival?.toIso8601String(),
      'actualArrival': actualArrival?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  int get passengerCount => passengerIds.length;

  StopModel copyWith({
    String? id,
    String? routeId,
    int? orderIndex,
    double? latitude,
    double? longitude,
    String? address,
    List<String>? passengerIds,
    List<UserModel>? passengers,
    DateTime? estimatedArrival,
    DateTime? actualArrival,
    bool? isCompleted,
  }) {
    return StopModel(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      orderIndex: orderIndex ?? this.orderIndex,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      passengerIds: passengerIds ?? this.passengerIds,
      passengers: passengers ?? this.passengers,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      actualArrival: actualArrival ?? this.actualArrival,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
