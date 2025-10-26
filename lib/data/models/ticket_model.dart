class Ticket {
  final String id;
  final String routeId;
  final String companyId;
  final String companyName;
  final String companyLogo;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double price;
  final int availableSeats;
  final int totalSeats;
  final String busType;
  final List<String> amenities;
  final double rating;
  final int reviewCount;
  final String duration;
  final bool isDirectRoute;
  final List<String> stops;

  const Ticket({
    required this.id,
    required this.routeId,
    required this.companyId,
    required this.companyName,
    required this.companyLogo,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.availableSeats,
    required this.totalSeats,
    required this.busType,
    required this.amenities,
    required this.rating,
    required this.reviewCount,
    required this.duration,
    required this.isDirectRoute,
    required this.stops,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      routeId: json['route_id'] as String,
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String,
      companyLogo: json['company_logo'] as String? ?? '',
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      departureTime: DateTime.parse(json['departure_time'] as String),
      arrivalTime: DateTime.parse(json['arrival_time'] as String),
      price: (json['price'] as num).toDouble(),
      availableSeats: json['available_seats'] as int,
      totalSeats: json['total_seats'] as int,
      busType: json['bus_type'] as String,
      amenities: List<String>.from(json['amenities'] ?? []),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      duration: json['duration'] as String,
      isDirectRoute: json['is_direct_route'] as bool? ?? true,
      stops: List<String>.from(json['stops'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'route_id': routeId,
      'company_id': companyId,
      'company_name': companyName,
      'company_logo': companyLogo,
      'origin': origin,
      'destination': destination,
      'departure_time': departureTime.toIso8601String(),
      'arrival_time': arrivalTime.toIso8601String(),
      'price': price,
      'available_seats': availableSeats,
      'total_seats': totalSeats,
      'bus_type': busType,
      'amenities': amenities,
      'rating': rating,
      'review_count': reviewCount,
      'duration': duration,
      'is_direct_route': isDirectRoute,
      'stops': stops,
    };
  }

  // Getters útiles
  bool get hasAvailableSeats => availableSeats > 0;
  double get occupancyPercentage => ((totalSeats - availableSeats) / totalSeats) * 100;
  String get formattedPrice => '\$${price.toStringAsFixed(0)}';
  String get departureTimeFormatted => '${departureTime.hour.toString().padLeft(2, '0')}:${departureTime.minute.toString().padLeft(2, '0')}';
  String get arrivalTimeFormatted => '${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}';
}

class TicketFilter {
  final String? origin;
  final String? destination;
  final DateTime? departureDate;
  final DateTime? returnDate;
  final int? passengers;
  final double? minPrice;
  final double? maxPrice;
  final String? departureTimeRange; // 'morning', 'afternoon', 'evening', 'night'
  final List<String>? companies;
  final List<String>? amenities;
  final bool? directRouteOnly;
  final String? sortBy; // 'price', 'departure', 'duration', 'rating'
  final bool? ascending;

  const TicketFilter({
    this.origin,
    this.destination,
    this.departureDate,
    this.returnDate,
    this.passengers,
    this.minPrice,
    this.maxPrice,
    this.departureTimeRange,
    this.companies,
    this.amenities,
    this.directRouteOnly,
    this.sortBy,
    this.ascending,
  });

  factory TicketFilter.fromJson(Map<String, dynamic> json) {
    return TicketFilter(
      origin: json['origin'] as String?,
      destination: json['destination'] as String?,
      departureDate: json['departure_date'] != null ? DateTime.parse(json['departure_date'] as String) : null,
      returnDate: json['return_date'] != null ? DateTime.parse(json['return_date'] as String) : null,
      passengers: json['passengers'] as int?,
      minPrice: (json['min_price'] as num?)?.toDouble(),
      maxPrice: (json['max_price'] as num?)?.toDouble(),
      departureTimeRange: json['departure_time_range'] as String?,
      companies: json['companies'] != null ? List<String>.from(json['companies']) : null,
      amenities: json['amenities'] != null ? List<String>.from(json['amenities']) : null,
      directRouteOnly: json['direct_route_only'] as bool?,
      sortBy: json['sort_by'] as String?,
      ascending: json['ascending'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'destination': destination,
      'departure_date': departureDate?.toIso8601String(),
      'return_date': returnDate?.toIso8601String(),
      'passengers': passengers,
      'min_price': minPrice,
      'max_price': maxPrice,
      'departure_time_range': departureTimeRange,
      'companies': companies,
      'amenities': amenities,
      'direct_route_only': directRouteOnly,
      'sort_by': sortBy,
      'ascending': ascending,
    };
  }

  TicketFilter copyWith({
    String? origin,
    String? destination,
    DateTime? departureDate,
    DateTime? returnDate,
    int? passengers,
    double? minPrice,
    double? maxPrice,
    String? departureTimeRange,
    List<String>? companies,
    List<String>? amenities,
    bool? directRouteOnly,
    String? sortBy,
    bool? ascending,
  }) {
    return TicketFilter(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      passengers: passengers ?? this.passengers,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      departureTimeRange: departureTimeRange ?? this.departureTimeRange,
      companies: companies ?? this.companies,
      amenities: amenities ?? this.amenities,
      directRouteOnly: directRouteOnly ?? this.directRouteOnly,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }
}

class Booking {
  final String id;
  final String ticketId;
  final String userId;
  final int passengerCount;
  final double totalPrice;
  final DateTime bookingDate;
  BookingStatus status;
  final List<String> seatNumbers;
  final Ticket ticket;
  
  // Campos de calificación
  int? driverRating;
  String? driverComment;
  List<String>? driverTags;
  int? passengerRating;
  String? passengerComment;
  List<String>? passengerTags;
  bool hasRatedDriver;
  bool hasRatedAsPassenger;

  Booking({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.passengerCount,
    required this.totalPrice,
    required this.bookingDate,
    required this.status,
    required this.seatNumbers,
    required this.ticket,
    this.driverRating,
    this.driverComment,
    this.driverTags,
    this.passengerRating,
    this.passengerComment,
    this.passengerTags,
    this.hasRatedDriver = false,
    this.hasRatedAsPassenger = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'userId': userId,
      'passengerCount': passengerCount,
      'totalPrice': totalPrice,
      'bookingDate': bookingDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'seatNumbers': seatNumbers,
      'ticket': ticket.toJson(),
      'driverRating': driverRating,
      'driverComment': driverComment,
      'driverTags': driverTags,
      'passengerRating': passengerRating,
      'passengerComment': passengerComment,
      'passengerTags': passengerTags,
      'hasRatedDriver': hasRatedDriver,
      'hasRatedAsPassenger': hasRatedAsPassenger,
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      ticketId: json['ticketId'],
      userId: json['userId'],
      passengerCount: json['passengerCount'],
      totalPrice: json['totalPrice'].toDouble(),
      bookingDate: DateTime.parse(json['bookingDate']),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      seatNumbers: List<String>.from(json['seatNumbers']),
      ticket: Ticket.fromJson(json['ticket']),
      driverRating: json['driverRating'],
      driverComment: json['driverComment'],
      driverTags: json['driverTags'] != null ? List<String>.from(json['driverTags']) : null,
      passengerRating: json['passengerRating'],
      passengerComment: json['passengerComment'],
      passengerTags: json['passengerTags'] != null ? List<String>.from(json['passengerTags']) : null,
      hasRatedDriver: json['hasRatedDriver'] ?? false,
      hasRatedAsPassenger: json['hasRatedAsPassenger'] ?? false,
    );
  }
}

enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed,
}