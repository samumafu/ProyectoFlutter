class Company {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? nit;
  final String? description;
  final String? logoUrl;
  final bool isActive;
  final List<String> routes;
  final Map<String, dynamic>? settings;

  const Company({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    required this.routes,
    this.phone,
    this.address,
    this.nit,
    this.description,
    this.logoUrl,
    this.settings,
  });

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      nit: map['nit'] as String?,
      description: map['description'] as String?,
      logoUrl: map['logo_url'] as String?,
      isActive: (map['is_active'] as bool?) ?? false,
      routes: (map['routes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      settings: map['settings'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
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
      routes: routes ?? this.routes,
      settings: settings ?? this.settings,
    );
  }
}

class Driver {
  final int id;
  final String userId;
  final String name;
  final String? phone;
  final String? autoModel;
  final String? autoColor;
  final String? autoPlate;
  final bool available;
  final double? rating;

  const Driver({
    required this.id,
    required this.userId,
    required this.name,
    required this.available,
    this.phone,
    this.autoModel,
    this.autoColor,
    this.autoPlate,
    this.rating,
  });

  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: (map['id'] as num).toInt(),
      userId: map['user_id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      autoModel: map['auto_model'] as String?,
      autoColor: map['auto_color'] as String?,
      autoPlate: map['auto_plate'] as String?,
      available: (map['available'] as bool?) ?? false,
      rating: (map['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'auto_model': autoModel,
      'auto_color': autoColor,
      'auto_plate': autoPlate,
      'available': available,
      'rating': rating,
    };
  }
}