enum ReservationStatus {
  active,
  cancelled,
  completed,
}

class ReservationModel {
  final String id;
  final String userId;
  final String serviceId;
  final DateTime date;
  final ReservationStatus status;
  final bool willAttend;
  final DateTime createdAt;
  final String? cancelReason;

  ReservationModel({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.date,
    required this.status,
    required this.willAttend,
    required this.createdAt,
    this.cancelReason,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      serviceId: json['serviceId'] ?? '',
      date: DateTime.parse(json['date']),
      status: _parseStatus(json['status']),
      willAttend: json['willAttend'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      cancelReason: json['cancelReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'serviceId': serviceId,
      'date': date.toIso8601String(),
      'status': status.toString().split('.').last,
      'willAttend': willAttend,
      'createdAt': createdAt.toIso8601String(),
      'cancelReason': cancelReason,
    };
  }

  static ReservationStatus _parseStatus(dynamic status) {
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'cancelled':
          return ReservationStatus.cancelled;
        case 'completed':
          return ReservationStatus.completed;
        default:
          return ReservationStatus.active;
      }
    }
    return ReservationStatus.active;
  }

  String get statusText {
    switch (status) {
      case ReservationStatus.active:
        return willAttend ? 'Aktif' : 'Binmeyeceğim';
      case ReservationStatus.cancelled:
        return 'İptal Edildi';
      case ReservationStatus.completed:
        return 'Tamamlandı';
    }
  }

  ReservationModel copyWith({
    String? id,
    String? userId,
    String? serviceId,
    DateTime? date,
    ReservationStatus? status,
    bool? willAttend,
    DateTime? createdAt,
    String? cancelReason,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      date: date ?? this.date,
      status: status ?? this.status,
      willAttend: willAttend ?? this.willAttend,
      createdAt: createdAt ?? this.createdAt,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }
}
