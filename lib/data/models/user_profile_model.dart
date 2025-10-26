class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final double passengerRating;
  final int totalTripsAsPassenger;
  final double driverRating;
  final int totalTripsAsDriver;
  final bool isDriver;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final List<String> favoriteRoutes;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.passengerRating = 0.0,
    this.totalTripsAsPassenger = 0,
    this.driverRating = 0.0,
    this.totalTripsAsDriver = 0,
    this.isDriver = false,
    required this.createdAt,
    this.lastActiveAt,
    this.favoriteRoutes = const [],
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    double? passengerRating,
    int? totalTripsAsPassenger,
    double? driverRating,
    int? totalTripsAsDriver,
    bool? isDriver,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    List<String>? favoriteRoutes,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      passengerRating: passengerRating ?? this.passengerRating,
      totalTripsAsPassenger: totalTripsAsPassenger ?? this.totalTripsAsPassenger,
      driverRating: driverRating ?? this.driverRating,
      totalTripsAsDriver: totalTripsAsDriver ?? this.totalTripsAsDriver,
      isDriver: isDriver ?? this.isDriver,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      favoriteRoutes: favoriteRoutes ?? this.favoriteRoutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'passenger_rating': passengerRating,
      'total_trips_as_passenger': totalTripsAsPassenger,
      'driver_rating': driverRating,
      'total_trips_as_driver': totalTripsAsDriver,
      'is_driver': isDriver,
      'created_at': createdAt.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
      'favorite_routes': favoriteRoutes,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      passengerRating: (json['passenger_rating'] as num?)?.toDouble() ?? 0.0,
      totalTripsAsPassenger: json['total_trips_as_passenger'] as int? ?? 0,
      driverRating: (json['driver_rating'] as num?)?.toDouble() ?? 0.0,
      totalTripsAsDriver: json['total_trips_as_driver'] as int? ?? 0,
      isDriver: json['is_driver'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActiveAt: json['last_active_at'] != null 
          ? DateTime.parse(json['last_active_at'] as String)
          : null,
      favoriteRoutes: List<String>.from(json['favorite_routes'] as List? ?? []),
    );
  }
}