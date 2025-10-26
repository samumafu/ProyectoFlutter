class Driver {
  final String id;
  final String name;
  final String lastName;
  final String phoneNumber;
  final String emergencyPhone;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final double rating;
  final int totalTrips;
  final String photoUrl;
  final int yearsExperience;
  final List<String> languages;

  const Driver({
    required this.id,
    required this.name,
    required this.lastName,
    required this.phoneNumber,
    required this.emergencyPhone,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.rating,
    required this.totalTrips,
    this.photoUrl = '',
    required this.yearsExperience,
    this.languages = const ['Español'],
  });

  String get fullName => '$name $lastName';

  String get displayRating => rating.toStringAsFixed(1);

  bool get isLicenseValid => licenseExpiry.isAfter(DateTime.now());

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      name: json['name'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      emergencyPhone: json['emergencyPhone'],
      licenseNumber: json['licenseNumber'],
      licenseExpiry: DateTime.parse(json['licenseExpiry']),
      rating: json['rating'].toDouble(),
      totalTrips: json['totalTrips'],
      photoUrl: json['photoUrl'] ?? '',
      yearsExperience: json['yearsExperience'],
      languages: List<String>.from(json['languages'] ?? ['Español']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'emergencyPhone': emergencyPhone,
      'licenseNumber': licenseNumber,
      'licenseExpiry': licenseExpiry.toIso8601String(),
      'rating': rating,
      'totalTrips': totalTrips,
      'photoUrl': photoUrl,
      'yearsExperience': yearsExperience,
      'languages': languages,
    };
  }
}