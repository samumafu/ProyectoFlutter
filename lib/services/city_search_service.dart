import '../data/constants/narino_destinations.dart';

class CitySearchService {
  // Ciudades principales de Colombia para búsqueda ampliada
  static const List<Map<String, String>> colombianCities = [
    {'name': 'Bogotá', 'region': 'Cundinamarca', 'type': 'capital'},
    {'name': 'Medellín', 'region': 'Antioquia', 'type': 'principal'},
    {'name': 'Cali', 'region': 'Valle del Cauca', 'type': 'principal'},
    {'name': 'Barranquilla', 'region': 'Atlántico', 'type': 'principal'},
    {'name': 'Cartagena', 'region': 'Bolívar', 'type': 'principal'},
    {'name': 'Bucaramanga', 'region': 'Santander', 'type': 'principal'},
    {'name': 'Pereira', 'region': 'Risaralda', 'type': 'principal'},
    {'name': 'Manizales', 'region': 'Caldas', 'type': 'principal'},
    {'name': 'Armenia', 'region': 'Quindío', 'type': 'principal'},
    {'name': 'Ibagué', 'region': 'Tolima', 'type': 'principal'},
    {'name': 'Neiva', 'region': 'Huila', 'type': 'principal'},
    {'name': 'Villavicencio', 'region': 'Meta', 'type': 'principal'},
    {'name': 'Popayán', 'region': 'Cauca', 'type': 'principal'},
    {'name': 'Montería', 'region': 'Córdoba', 'type': 'principal'},
    {'name': 'Valledupar', 'region': 'Cesar', 'type': 'principal'},
    {'name': 'Santa Marta', 'region': 'Magdalena', 'type': 'principal'},
    {'name': 'Sincelejo', 'region': 'Sucre', 'type': 'principal'},
    {'name': 'Riohacha', 'region': 'La Guajira', 'type': 'principal'},
    {'name': 'Quibdó', 'region': 'Chocó', 'type': 'principal'},
    {'name': 'Florencia', 'region': 'Caquetá', 'type': 'principal'},
    {'name': 'Mocoa', 'region': 'Putumayo', 'type': 'principal'},
    {'name': 'Yopal', 'region': 'Casanare', 'type': 'principal'},
    {'name': 'Arauca', 'region': 'Arauca', 'type': 'principal'},
    {'name': 'Tunja', 'region': 'Boyacá', 'type': 'principal'},
    {'name': 'Cúcuta', 'region': 'Norte de Santander', 'type': 'principal'},
  ];

  /// Busca ciudades basándose en el texto de consulta
  static List<Map<String, dynamic>> searchCities(String query) {
    if (query.isEmpty) {
      return _getAllCities();
    }

    final normalizedQuery = _normalizeText(query);
    final results = <Map<String, dynamic>>[];

    // Buscar en municipios de Nariño
    for (final municipality in NarinoDestinations.municipalities) {
      final normalizedMunicipality = _normalizeText(municipality);
      final region = NarinoDestinations.getRegionForDestination(municipality);
      final normalizedRegion = _normalizeText(region);

      if (normalizedMunicipality.contains(normalizedQuery) ||
          normalizedRegion.contains(normalizedQuery)) {
        results.add({
          'name': municipality,
          'region': 'Nariño - $region',
          'type': 'municipality',
          'priority': normalizedMunicipality.startsWith(normalizedQuery) ? 1 : 2,
          'isLocal': true,
        });
      }
    }

    // Buscar en ciudades principales de Colombia
    for (final city in colombianCities) {
      final normalizedCity = _normalizeText(city['name']!);
      final normalizedRegion = _normalizeText(city['region']!);

      if (normalizedCity.contains(normalizedQuery) ||
          normalizedRegion.contains(normalizedQuery)) {
        results.add({
          'name': city['name']!,
          'region': city['region']!,
          'type': city['type']!,
          'priority': normalizedCity.startsWith(normalizedQuery) ? 1 : 3,
          'isLocal': false,
        });
      }
    }

    // Ordenar por prioridad y relevancia
    results.sort((a, b) {
      final priorityComparison = a['priority'].compareTo(b['priority']);
      if (priorityComparison != 0) return priorityComparison;
      
      // Priorizar ciudades locales de Nariño
      if (a['isLocal'] && !b['isLocal']) return -1;
      if (!a['isLocal'] && b['isLocal']) return 1;
      
      return a['name'].compareTo(b['name']);
    });

    return results.take(20).toList(); // Limitar a 20 resultados
  }

  /// Obtiene todas las ciudades disponibles
  static List<Map<String, dynamic>> _getAllCities() {
    final results = <Map<String, dynamic>>[];

    // Agregar municipios de Nariño primero
    for (final municipality in NarinoDestinations.municipalities) {
      final region = NarinoDestinations.getRegionForDestination(municipality);
      results.add({
        'name': municipality,
        'region': 'Nariño - $region',
        'type': 'municipality',
        'priority': 1,
        'isLocal': true,
      });
    }

    // Agregar ciudades principales de Colombia
    for (final city in colombianCities) {
      results.add({
        'name': city['name']!,
        'region': city['region']!,
        'type': city['type']!,
        'priority': 2,
        'isLocal': false,
      });
    }

    return results;
  }

  /// Obtiene ciudades por región específica
  static List<Map<String, dynamic>> getCitiesByRegion(String region) {
    final results = <Map<String, dynamic>>[];

    if (region == 'Nariño') {
      for (final municipality in NarinoDestinations.municipalities) {
        final municipalityRegion = NarinoDestinations.getRegionForDestination(municipality);
        results.add({
          'name': municipality,
          'region': 'Nariño - $municipalityRegion',
          'type': 'municipality',
          'priority': 1,
          'isLocal': true,
        });
      }
    } else {
      // Buscar en ciudades principales por región
      for (final city in colombianCities) {
        if (city['region'] == region) {
          results.add({
            'name': city['name']!,
            'region': city['region']!,
            'type': city['type']!,
            'priority': 1,
            'isLocal': false,
          });
        }
      }
    }

    return results;
  }

  /// Obtiene las ciudades más populares para mostrar por defecto
  static List<Map<String, dynamic>> getPopularCities() {
    return [
      // Ciudades principales de Nariño
      {'name': 'Pasto', 'region': 'Nariño - Centro', 'type': 'municipality', 'isLocal': true},
      {'name': 'Ipiales', 'region': 'Nariño - Norte', 'type': 'municipality', 'isLocal': true},
      {'name': 'Tumaco', 'region': 'Nariño - Pacífico', 'type': 'municipality', 'isLocal': true},
      {'name': 'Túquerres', 'region': 'Nariño - Norte', 'type': 'municipality', 'isLocal': true},
      
      // Ciudades principales de Colombia
      {'name': 'Bogotá', 'region': 'Cundinamarca', 'type': 'capital', 'isLocal': false},
      {'name': 'Cali', 'region': 'Valle del Cauca', 'type': 'principal', 'isLocal': false},
      {'name': 'Medellín', 'region': 'Antioquia', 'type': 'principal', 'isLocal': false},
      {'name': 'Popayán', 'region': 'Cauca', 'type': 'principal', 'isLocal': false},
    ];
  }

  /// Normaliza texto para búsqueda (sin acentos, minúsculas)
  static String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  /// Obtiene sugerencias basadas en el historial del usuario
  static List<Map<String, dynamic>> getSuggestionsForUser(List<String> recentSearches) {
    final suggestions = <Map<String, dynamic>>[];
    
    // Agregar búsquedas recientes
    for (final search in recentSearches.take(5)) {
      final searchResults = searchCities(search);
      if (searchResults.isNotEmpty) {
        suggestions.add({
          ...searchResults.first,
          'isRecent': true,
        });
      }
    }
    
    // Agregar TODOS los municipios de Nariño primero
    for (final municipality in NarinoDestinations.municipalities) {
      if (!suggestions.any((s) => s['name'] == municipality)) {
        final region = NarinoDestinations.getRegionForDestination(municipality);
        suggestions.add({
          'name': municipality,
          'region': 'Nariño - $region',
          'type': 'municipality',
          'priority': 1,
          'isLocal': true,
          'isRecent': false,
        });
      }
    }
    
    // Agregar ciudades principales de Colombia
    for (final city in colombianCities) {
      if (!suggestions.any((s) => s['name'] == city['name'])) {
        suggestions.add({
          'name': city['name']!,
          'region': city['region']!,
          'type': city['type']!,
          'priority': 2,
          'isLocal': false,
          'isRecent': false,
        });
      }
    }
    
    return suggestions;
  }
}