import '../data/constants/narino_destinations.dart';

class CitySearchService {
  // SOLO MUNICIPIOS DE NARIÑO - No incluir otras ciudades de Colombia

  /// Busca ciudades basándose en el texto de consulta - SOLO MUNICIPIOS DE NARIÑO
  static List<Map<String, dynamic>> searchCities(String query) {
    if (query.isEmpty) {
      return _getAllCities();
    }

    final normalizedQuery = _normalizeText(query);
    final results = <Map<String, dynamic>>[];

    // Buscar ÚNICAMENTE en municipios de Nariño
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

    // Ordenar por prioridad y relevancia
    results.sort((a, b) {
      final priorityComparison = a['priority'].compareTo(b['priority']);
      if (priorityComparison != 0) return priorityComparison;
      return a['name'].compareTo(b['name']);
    });

    return results.take(20).toList(); // Limitar a 20 resultados
  }

  /// Obtiene todas las ciudades disponibles - SOLO MUNICIPIOS DE NARIÑO
  static List<Map<String, dynamic>> _getAllCities() {
    final results = <Map<String, dynamic>>[];

    // Agregar ÚNICAMENTE municipios de Nariño
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

    return results;
  }

  /// Obtiene ciudades por región específica - SOLO NARIÑO
  static List<Map<String, dynamic>> getCitiesByRegion(String region) {
    final results = <Map<String, dynamic>>[];

    // Solo devolver municipios de Nariño
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

    return results;
  }

  /// Obtiene las ciudades más populares para mostrar por defecto - SOLO NARIÑO
  static List<Map<String, dynamic>> getPopularCities() {
    return [
      // Ciudades principales de Nariño
      {'name': 'Pasto', 'region': 'Nariño - Centro', 'type': 'municipality', 'isLocal': true},
      {'name': 'Ipiales', 'region': 'Nariño - Norte', 'type': 'municipality', 'isLocal': true},
      {'name': 'Tumaco', 'region': 'Nariño - Pacífico', 'type': 'municipality', 'isLocal': true},
      {'name': 'Túquerres', 'region': 'Nariño - Norte', 'type': 'municipality', 'isLocal': true},
      {'name': 'Samaniego', 'region': 'Nariño - Norte', 'type': 'municipality', 'isLocal': true},
      {'name': 'La Unión', 'region': 'Nariño - Norte', 'type': 'municipality', 'isLocal': true},
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

  /// Obtiene sugerencias para mostrar al usuario - SOLO MUNICIPIOS DE NARIÑO
  static List<Map<String, dynamic>> getSuggestionsForUser(List<String> recentSearches) {
    final suggestions = <Map<String, dynamic>>[];
    
    // Agregar búsquedas recientes (solo si son de Nariño)
    for (final search in recentSearches.take(3)) {
      if (NarinoDestinations.municipalities.contains(search)) {
        final region = NarinoDestinations.getRegionForDestination(search);
        suggestions.add({
          'name': search,
          'region': 'Nariño - $region',
          'type': 'municipality',
          'priority': 0,
          'isLocal': true,
          'isRecent': true,
        });
      }
    }
    
    // Agregar TODOS los municipios de Nariño
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
    
    return suggestions;
  }
}