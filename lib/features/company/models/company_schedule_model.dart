// 📝 lib/features/company/models/company_schedule_model.dart

import 'dart:convert';
import 'package:flutter/foundation.dart'; // Necesario para DateTime

class CompanySchedule {
  final String id;
  final String companyId;
  final String origin;
  final String destination;
  final String departureTime; // store as ISO/string to match DB
  final String arrivalTime; // store as ISO/string to match DB
  final double price;
  final int availableSeats;
  final int totalSeats;
  final String? vehicleType;
  final String? vehicleId;
  final bool isActive;
  final Map<String, dynamic>? additionalInfo;

  const CompanySchedule({
    required this.id,
    required this.companyId,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.availableSeats,
    required this.totalSeats,
    required this.isActive,
    this.vehicleType,
    this.vehicleId,
    this.additionalInfo,
  });

  factory CompanySchedule.fromMap(Map<String, dynamic> map) {
    String? _asString(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      if (v is Map || v is List) {
        try {
          return jsonEncode(v);
        } catch (_) {
          return v.toString();
        }
      }
      return v.toString();
    }
    int _asInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    double _asDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    bool _asBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().toLowerCase();
      return s == 'true' || s == 't' || s == '1';
    }

    Map<String, dynamic>? _asJsonMap(dynamic v) {
      if (v == null) return null;
      if (v is Map<String, dynamic>) return v;
      if (v is Map) {
        return v.map((key, value) => MapEntry(key.toString(), value));
      }
      if (v is String) {
        try {
          final decoded = jsonDecode(v);
          if (decoded is Map<String, dynamic>) return decoded;
          if (decoded is Map) {
            return decoded.map((k, val) => MapEntry(k.toString(), val));
          }
        } catch (_) {}
      }
      return {'value': v};
    }

    return CompanySchedule(
      id: _asString(map['id']) ?? '',
      companyId: _asString(map['company_id']) ?? '',
      origin: _asString(map['origin']) ?? '',
      destination: _asString(map['destination']) ?? '',
      departureTime: _asString(map['departure_time']) ?? '',
      arrivalTime: _asString(map['arrival_time']) ?? '',
      price: _asDouble(map['price']),
      availableSeats: _asInt(map['available_seats']),
      totalSeats: _asInt(map['total_seats']),
      vehicleType: _asString(map['vehicle_type']),
      vehicleId: _asString(map['vehicle_id']),
      isActive: _asBool(map['is_active']),
      additionalInfo: _asJsonMap(map['additional_info']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'origin': origin,
      'destination': destination,
      'departure_time': departureTime,
      'arrival_time': arrivalTime,
      'price': price,
      'available_seats': availableSeats,
      'total_seats': totalSeats,
      'vehicle_type': vehicleType,
      'vehicle_id': vehicleId,
      'is_active': isActive,
      'additional_info': additionalInfo,
    };
  }
}

// 🛑 IMPORTANTE: Las clases Reservation, ChatMessage y ReservationHistory han sido ELIMINADAS de este archivo.
// Asegúrate de que todas las demás dependencias tengan las nuevas declaraciones 'import'.