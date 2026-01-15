class DailyRouteModel {
  final int id;
  final String name;
  final int? vehicleId;
  final String? vehiclePlate;
  final String? driverName;
  final DateTime routeDate;
  final int status; // 0: Planned, 1: In Progress, 2: Completed
  final DateTime? estimatedStartTime;
  final DateTime? actualStartTime;
  final DateTime? estimatedEndTime;
  final DateTime? actualEndTime;
  final int stopCount;
  final bool isActive;

  DailyRouteModel({
    required this.id,
    required this.name,
    this.vehicleId,
    this.vehiclePlate,
    this.driverName,
    required this.routeDate,
    required this.status,
    this.estimatedStartTime,
    this.actualStartTime,
    this.estimatedEndTime,
    this.actualEndTime,
    required this.stopCount,
    required this.isActive,
  });

  factory DailyRouteModel.fromJson(Map<String, dynamic> json) {
    return DailyRouteModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Rota',
      vehicleId: json['vehicleId'],
      vehiclePlate: json['vehiclePlate'],
      driverName: json['driverName'],
      routeDate: json['routeDate'] != null
          ? DateTime.parse(json['routeDate'])
          : DateTime.now(),
      status: json['status'] ?? 0,
      estimatedStartTime: json['estimatedStartTime'] != null
          ? DateTime.parse(json['estimatedStartTime'])
          : null,
      actualStartTime: json['actualStartTime'] != null
          ? DateTime.parse(json['actualStartTime'])
          : null,
      estimatedEndTime: json['estimatedEndTime'] != null
          ? DateTime.parse(json['estimatedEndTime'])
          : null,
      actualEndTime: json['actualEndTime'] != null
          ? DateTime.parse(json['actualEndTime'])
          : null,
      stopCount: json['stopCount'] ?? 0,
      isActive: json['isActive'] ?? false,
    );
  }

  String get statusText {
    switch (status) {
      case 0:
        return 'Planlandı';
      case 1:
        return 'Devam Ediyor';
      case 2:
        return 'Tamamlandı';
      default:
        return 'Bilinmiyor';
    }
  }

  String get formattedDate {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${routeDate.day} ${months[routeDate.month - 1]} ${routeDate.year}';
  }

  String? get formattedStartTime {
    if (estimatedStartTime == null) return null;
    return '${estimatedStartTime!.hour.toString().padLeft(2, '0')}:${estimatedStartTime!.minute.toString().padLeft(2, '0')}';
  }

  DateTime? get startTime => estimatedStartTime ?? actualStartTime;
}
