enum UserRole {
  passenger,
  driver,
  admin,
}

class StopLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? description;

  StopLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.description,
  });

  factory StopLocation.fromJson(Map<String, dynamic> json) {
    return StopLocation(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'description': description,
    };
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? profileImageUrl;
  final StopLocation? homeStop;
  final bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImageUrl,
    this.homeStop,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: _parseRole(json['role']),
      profileImageUrl: json['profileImageUrl'],
      homeStop: json['homeStop'] != null
          ? StopLocation.fromJson(json['homeStop'])
          : null,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toString().split('.').last,
      'profileImageUrl': profileImageUrl,
      'homeStop': homeStop?.toJson(),
      'isActive': isActive,
    };
  }

  static UserRole _parseRole(dynamic role) {
    if (role is String) {
      switch (role.toLowerCase()) {
        case 'driver':
          return UserRole.driver;
        case 'admin':
          return UserRole.admin;
        case 'passenger':
        default:
          return UserRole.passenger;
      }
    }
    return UserRole.passenger;
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? profileImageUrl,
    StopLocation? homeStop,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      homeStop: homeStop ?? this.homeStop,
      isActive: isActive ?? this.isActive,
    );
  }
}
