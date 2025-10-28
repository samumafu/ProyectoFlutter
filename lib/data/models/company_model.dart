class Company {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String nit;
  final String description;
  final String logoUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> routes;
  final Map<String, dynamic> settings;

  Company({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.nit,
    this.description = '',
    this.logoUrl = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.routes = const [],
    this.settings = const {},
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      nit: json['nit'] ?? '',
      description: json['description'] ?? '',
      logoUrl: json['logo_url'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      routes: List<String>.from(json['routes'] ?? []),
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'nit': nit,
      'description': description,
      'logo_url': logoUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'routes': routes,
      'settings': settings,
    };
  }

  Company copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? nit,
    String? description,
    String? logoUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? routes,
    Map<String, dynamic>? settings,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      nit: nit ?? this.nit,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      routes: routes ?? this.routes,
      settings: settings ?? this.settings,
    );
  }

  @override
  String toString() {
    return 'Company(id: $id, name: $name, email: $email, nit: $nit, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Company && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class CompanySchedule {
  final String id;
  final String companyId;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double price;
  final int availableSeats;
  final int totalSeats;
  final String vehicleType;
  final String vehicleId;
  final bool isActive;
  final Map<String, dynamic> additionalInfo;
  final String? companyName;

  CompanySchedule({
    required this.id,
    required this.companyId,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.availableSeats,
    required this.totalSeats,
    required this.vehicleType,
    required this.vehicleId,
    this.isActive = true,
    this.additionalInfo = const {},
    this.companyName,
  });

  factory CompanySchedule.fromJson(Map<String, dynamic> json) {
    return CompanySchedule(
      id: json['id'] ?? '',
      companyId: json['company_id'] ?? '',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      departureTime: DateTime.parse(json['departure_time']),
      arrivalTime: DateTime.parse(json['arrival_time']),
      price: (json['price'] ?? 0.0).toDouble(),
      availableSeats: json['available_seats'] ?? 0,
      totalSeats: json['total_seats'] ?? 0,
      vehicleType: json['vehicle_type'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      isActive: json['is_active'] ?? true,
      additionalInfo: Map<String, dynamic>.from(json['additional_info'] ?? {}),
      // Usar company_name directamente si está disponible, o 'Empresa' como fallback
      companyName: json['company_name'] ?? json['companies']?['name'] ?? 'Empresa',
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'company_id': companyId,
      'origin': origin,
      'destination': destination,
      'departure_time': departureTime.toIso8601String(),
      'arrival_time': arrivalTime.toIso8601String(),
      'price': price,
      'available_seats': availableSeats,
      'total_seats': totalSeats,
      'vehicle_type': vehicleType,
      'vehicle_id': vehicleId,
      'is_active': isActive,
      'additional_info': additionalInfo,
    };
    
    // Solo incluir el id si no está vacío
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }

  CompanySchedule copyWith({
    String? id,
    String? companyId,
    String? origin,
    String? destination,
    DateTime? departureTime,
    DateTime? arrivalTime,
    double? price,
    int? availableSeats,
    int? totalSeats,
    String? vehicleType,
    String? vehicleId,
    bool? isActive,
    Map<String, dynamic>? additionalInfo,
    String? companyName,
  }) {
    return CompanySchedule(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      price: price ?? this.price,
      availableSeats: availableSeats ?? this.availableSeats,
      totalSeats: totalSeats ?? this.totalSeats,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleId: vehicleId ?? this.vehicleId,
      isActive: isActive ?? this.isActive,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      companyName: companyName ?? this.companyName,
    );
  }
}