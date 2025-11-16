// lib/features/driver/models/driver_model.dart

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

  // 🚨 MÉTODO FALTANTE: FACTORY CONSTRUCTOR FROMMAP
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

  // 🚨 MÉTODO FALTANTE: TOMAP
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