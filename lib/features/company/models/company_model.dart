// lib/features/company/models/company_model.dart

import 'dart:convert';

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
    String _asString(dynamic v) {
      if (v == null) return '';
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
    Map<String, dynamic>? _asJsonMap(dynamic v) {
      if (v == null) return null;
      if (v is Map<String, dynamic>) return v;
      if (v is Map) {
        return v.map((k, val) => MapEntry(k.toString(), val));
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

    return Company(
      id: _asString(map['id']),
      name: _asString(map['name']),
      email: _asString(map['email']),
      phone: (map['phone'] == null) ? null : _asString(map['phone']),
      address: (map['address'] == null) ? null : _asString(map['address']),
      nit: (map['nit'] == null) ? null : _asString(map['nit']),
      description: (map['description'] == null) ? null : _asString(map['description']),
      logoUrl: (map['logo_url'] == null) ? null : _asString(map['logo_url']),
      isActive: (map['is_active'] as bool?) ?? false,
      routes: (map['routes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      settings: _asJsonMap(map['settings']),
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