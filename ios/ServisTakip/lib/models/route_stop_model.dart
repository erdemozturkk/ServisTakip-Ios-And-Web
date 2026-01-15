class RouteStopModel {
  final int id;
  final int stopId;
  final String stopName;
  final double latitude;
  final double longitude;
  final int sequenceOrder;
  final int status; // 0: Not started, 1: Arrived, 2: Completed
  final DateTime? estimatedArrivalTime;
  final DateTime? actualArrivalTime;

  RouteStopModel({
    required this.id,
    required this.stopId,
    required this.stopName,
    required this.latitude,
    required this.longitude,
    required this.sequenceOrder,
    required this.status,
    this.estimatedArrivalTime,
    this.actualArrivalTime,
  });

  factory RouteStopModel.fromJson(Map<String, dynamic> json) {
    return RouteStopModel(
      id: json['id'] ?? 0,
      stopId: json['stopId'] ?? 0,
      stopName: json['stopName'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      sequenceOrder: json['sequenceOrder'] ?? 0,
      status: json['status'] ?? 0,
      estimatedArrivalTime: json['estimatedArrivalTime'] != null
          ? DateTime.parse(json['estimatedArrivalTime'])
          : null,
      actualArrivalTime: json['actualArrivalTime'] != null
          ? DateTime.parse(json['actualArrivalTime'])
          : null,
    );
  }

  bool get isCompleted => status == 2;
  bool get isArrived => status >= 1;
  
  String get statusText {
    switch (status) {
      case 0:
        return 'Başlanmadı';
      case 1:
        return 'Varıldı';
      case 2:
        return 'Tamamlandı';
      default:
        return 'Bilinmiyor';
    }
  }
}
