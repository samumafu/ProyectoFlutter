import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'user_preferences_service.dart';

class AITravelService {
  static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY'; // Reemplazar con tu API key
  static const String _geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
  static final UserPreferencesService _prefsService = UserPreferencesService();

  /// Obtiene recomendaciones de viaje basadas en origen y destino
  static Future<Map<String, dynamic>> getTravelRecommendations({
    required String origin,
    required String destination,
    DateTime? preferredDate,
    int passengers = 1,
    String? preferences,
  }) async {
    try {
      // Obtener datos personalizados del usuario
      final personalizedData = await _prefsService.getPersonalizedData();
      
      final prompt = _buildTravelRecommendationPrompt(
        origin: origin,
        destination: destination,
        preferredDate: preferredDate,
        passengers: passengers,
        preferences: preferences,
        personalizedData: personalizedData,
      );

      final response = await _callGeminiAPI(prompt);
      return _parseTravelRecommendations(response);
    } catch (e) {
      print('Error getting travel recommendations: $e');
      return _getFallbackRecommendations(origin, destination);
    }
  }

  /// Obtiene horarios flexibles y sugerencias de fechas
  static Future<Map<String, dynamic>> getFlexibleSchedules({
    required String origin,
    required String destination,
    DateTime? baseDate,
  }) async {
    try {
      final prompt = _buildFlexibleSchedulePrompt(
        origin: origin,
        destination: destination,
        baseDate: baseDate,
      );

      final response = await _callGeminiAPI(prompt);
      return _parseFlexibleSchedules(response);
    } catch (e) {
      print('Error getting flexible schedules: $e');
      return _getFallbackSchedules();
    }
  }

  /// Obtiene sugerencias innovadoras de viaje
  static Future<Map<String, dynamic>> getInnovativeSuggestions({
    required String origin,
    required String destination,
    String? travelPurpose,
    String? budget,
  }) async {
    try {
      final prompt = _buildInnovativeSuggestionsPrompt(
        origin: origin,
        destination: destination,
        travelPurpose: travelPurpose,
        budget: budget,
      );

      final response = await _callGeminiAPI(prompt);
      return _parseInnovativeSuggestions(response);
    } catch (e) {
      print('Error getting innovative suggestions: $e');
      return _getFallbackInnovativeSuggestions();
    }
  }

  /// Analiza patrones de viaje del usuario para recomendaciones personalizadas
  static Future<Map<String, dynamic>> getPersonalizedRecommendations({
    required List<Map<String, String>> travelHistory,
    required String currentOrigin,
    required String currentDestination,
  }) async {
    try {
      final prompt = _buildPersonalizedPrompt(
        travelHistory: travelHistory,
        currentOrigin: currentOrigin,
        currentDestination: currentDestination,
      );

      final response = await _callGeminiAPI(prompt);
      return _parsePersonalizedRecommendations(response);
    } catch (e) {
      print('Error getting personalized recommendations: $e');
      return _getFallbackPersonalizedRecommendations();
    }
  }

  // Métodos privados para construir prompts

  static String _buildTravelRecommendationPrompt({
    required String origin,
    required String destination,
    DateTime? preferredDate,
    int passengers = 1,
    String? preferences,
    Map<String, dynamic>? personalizedData,
  }) {
    final dateStr = preferredDate != null 
        ? preferredDate.toString().split(' ')[0] 
        : 'próximos días';
    
    // Construir información personalizada
    String personalizedInfo = '';
    if (personalizedData != null && personalizedData.isNotEmpty) {
      final recentSearches = personalizedData['recentSearches'] as List<dynamic>? ?? [];
      final favoriteRoutes = personalizedData['favoriteRoutes'] as List<dynamic>? ?? [];
      final aiPreferences = personalizedData['aiPreferences'] as Map<String, dynamic>? ?? {};
      
      personalizedInfo = '''

Información personalizada del usuario:
- Búsquedas recientes: ${recentSearches.take(5).join(', ')}
- Rutas favoritas: ${favoriteRoutes.take(3).map((r) => '${r['origin']} → ${r['destination']}').join(', ')}
- Preferencias de horario: ${aiPreferences['preferredTimeOfDay'] ?? 'No especificado'}
- Presupuesto preferido: ${aiPreferences['budgetRange'] ?? 'No especificado'}
- Intereses: ${(aiPreferences['interests'] as List<dynamic>?)?.join(', ') ?? 'No especificado'}
''';
    }
    
    return '''
Como experto en viajes en Colombia, especialmente en la región de Nariño, proporciona recomendaciones detalladas para un viaje de $origin a $destination.

Detalles del viaje:
- Origen: $origin
- Destino: $destination
- Fecha preferida: $dateStr
- Número de pasajeros: $passengers
- Preferencias adicionales: ${preferences ?? 'Ninguna especificada'}$personalizedInfo

Por favor proporciona:
1. Mejores horarios de salida (mañana, tarde, noche)
2. Duración estimada del viaje
3. Precio aproximado por persona
4. Recomendaciones sobre qué llevar
5. Puntos de interés en el destino
6. Consejos de seguridad específicos para la ruta
7. Mejor época para viajar

Responde en formato JSON con las siguientes claves:
{
  "bestTimes": ["horario1", "horario2", "horario3"],
  "duration": "tiempo estimado",
  "priceRange": "rango de precios",
  "packingTips": ["tip1", "tip2", "tip3"],
  "attractions": ["atracción1", "atracción2", "atracción3"],
  "safetyTips": ["consejo1", "consejo2"],
  "bestSeason": "descripción de la mejor época",
  "additionalInfo": "información adicional relevante"
}
''';
  }

  static String _buildFlexibleSchedulePrompt({
    required String origin,
    required String destination,
    DateTime? baseDate,
  }) {
    final dateStr = baseDate?.toString().split(' ')[0] ?? DateTime.now().toString().split(' ')[0];
    
    return '''
Como experto en transporte terrestre en Colombia, analiza los horarios más flexibles y económicos para viajar de $origin a $destination.

Fecha base: $dateStr

Proporciona:
1. Días de la semana más económicos
2. Horarios con mayor disponibilidad
3. Horarios con menor tráfico
4. Alternativas de fechas (±3 días)
5. Horarios de temporada baja vs alta

Responde en formato JSON:
{
  "cheapestDays": ["día1", "día2"],
  "bestAvailability": ["horario1", "horario2"],
  "lessTraffic": ["horario1", "horario2"],
  "alternativeDates": [
    {"date": "fecha", "reason": "razón", "savings": "ahorro estimado"}
  ],
  "seasonalTips": "consejos sobre temporadas",
  "flexibilityBenefits": "beneficios de ser flexible con horarios"
}
''';
  }

  static String _buildInnovativeSuggestionsPrompt({
    required String origin,
    required String destination,
    String? travelPurpose,
    String? budget,
  }) {
    return '''
Como consultor de viajes innovador, proporciona sugerencias creativas y únicas para un viaje de $origin a $destination.

Propósito del viaje: ${travelPurpose ?? 'No especificado'}
Presupuesto: ${budget ?? 'Flexible'}

Incluye sugerencias innovadoras como:
1. Rutas alternativas escénicas
2. Paradas intermedias interesantes
3. Experiencias locales únicas
4. Opciones de transporte combinado
5. Actividades en el camino
6. Recomendaciones gastronómicas
7. Opciones de alojamiento creativas

Responde en formato JSON:
{
  "scenicRoutes": ["ruta1", "ruta2"],
  "interestingStops": [
    {"place": "lugar", "activity": "actividad", "duration": "tiempo"}
  ],
  "localExperiences": ["experiencia1", "experiencia2"],
  "transportOptions": ["opción1", "opción2"],
  "roadActivities": ["actividad1", "actividad2"],
  "foodRecommendations": ["comida1", "comida2"],
  "accommodationIdeas": ["idea1", "idea2"],
  "budgetTips": "consejos para optimizar el presupuesto"
}
''';
  }

  static String _buildPersonalizedPrompt({
    required List<Map<String, String>> travelHistory,
    required String currentOrigin,
    required String currentDestination,
  }) {
    final historyStr = travelHistory.map((trip) => 
        '${trip['origin']} → ${trip['destination']} (${trip['date']})').join(', ');
    
    return '''
Basándote en el historial de viajes del usuario, proporciona recomendaciones personalizadas.

Historial de viajes: $historyStr
Viaje actual: $currentOrigin → $currentDestination

Analiza patrones y proporciona:
1. Preferencias detectadas
2. Rutas similares exitosas
3. Recomendaciones basadas en experiencias previas
4. Sugerencias de mejora
5. Nuevas experiencias basadas en gustos

Responde en formato JSON:
{
  "detectedPreferences": ["preferencia1", "preferencia2"],
  "similarSuccessfulRoutes": ["ruta1", "ruta2"],
  "basedOnHistory": ["recomendación1", "recomendación2"],
  "improvements": ["mejora1", "mejora2"],
  "newExperiences": ["experiencia1", "experiencia2"],
  "personalizedTips": "consejos específicos para este usuario"
}
''';
  }

  // Métodos para llamar a la API de Gemini

  static Future<String> _callGeminiAPI(String prompt) async {
    // Simulación de llamada a API (en implementación real usaría la API de Gemini)
    await Future.delayed(const Duration(seconds: 1));
    
    // Por ahora retornamos una respuesta simulada
    return '''
    {
      "candidates": [{
        "content": {
          "parts": [{
            "text": "Respuesta simulada de IA para el prompt: ${prompt.substring(0, 50)}..."
          }]
        }
      }]
    }
    ''';
  }

  // Métodos para parsear respuestas

  static Map<String, dynamic> _parseTravelRecommendations(String response) {
    // En implementación real, parsearía la respuesta JSON de Gemini
    return {
      'bestTimes': ['6:00 AM - 8:00 AM', '2:00 PM - 4:00 PM', '6:00 PM - 8:00 PM'],
      'duration': '2-3 horas dependiendo del tráfico',
      'priceRange': '\$15,000 - \$25,000 COP',
      'packingTips': ['Ropa cómoda', 'Snacks para el viaje', 'Cargador portátil'],
      'attractions': ['Centro histórico', 'Parques naturales', 'Museos locales'],
      'safetyTips': ['Viajar durante el día', 'Mantener documentos seguros'],
      'bestSeason': 'Temporada seca (diciembre a marzo)',
      'additionalInfo': 'Ruta con paisajes hermosos de la región andina'
    };
  }

  static Map<String, dynamic> _parseFlexibleSchedules(String response) {
    return {
      'cheapestDays': ['Martes', 'Miércoles', 'Jueves'],
      'bestAvailability': ['10:00 AM', '2:00 PM', '4:00 PM'],
      'lessTraffic': ['6:00 AM', '9:00 PM'],
      'alternativeDates': [
        {'date': 'Mañana', 'reason': 'Menor demanda', 'savings': '15%'},
        {'date': 'Próximo martes', 'reason': 'Día económico', 'savings': '20%'}
      ],
      'seasonalTips': 'Evitar fines de semana largos y festividades',
      'flexibilityBenefits': 'Hasta 25% de ahorro siendo flexible con fechas'
    };
  }

  static Map<String, dynamic> _parseInnovativeSuggestions(String response) {
    return {
      'scenicRoutes': ['Ruta por la cordillera', 'Camino costero'],
      'interestingStops': [
        {'place': 'Mirador Las Lajas', 'activity': 'Fotografía', 'duration': '30 min'},
        {'place': 'Mercado local', 'activity': 'Compras artesanales', 'duration': '1 hora'}
      ],
      'localExperiences': ['Degustación de café local', 'Visita a talleres artesanales'],
      'transportOptions': ['Bus + caminata ecológica', 'Transporte compartido'],
      'roadActivities': ['Observación de aves', 'Fotografía de paisajes'],
      'foodRecommendations': ['Empanadas nariñenses', 'Cuy asado', 'Café de altura'],
      'accommodationIdeas': ['Hostales familiares', 'Ecohoteles'],
      'budgetTips': 'Viajar en grupo para compartir costos de transporte'
    };
  }

  static Map<String, dynamic> _parsePersonalizedRecommendations(String response) {
    return {
      'detectedPreferences': ['Viajes matutinos', 'Rutas directas', 'Transporte cómodo'],
      'similarSuccessfulRoutes': ['Pasto-Ipiales', 'Pasto-Túquerres'],
      'basedOnHistory': ['Reservar con anticipación', 'Elegir asientos delanteros'],
      'improvements': ['Probar rutas escénicas', 'Considerar paradas gastronómicas'],
      'newExperiences': ['Tour fotográfico en ruta', 'Visita a pueblos intermedios'],
      'personalizedTips': 'Basado en tu historial, prefieres viajes eficientes y cómodos'
    };
  }

  // Métodos de respaldo (fallback)

  static Map<String, dynamic> _getFallbackRecommendations(String origin, String destination) {
    return {
      'bestTimes': ['7:00 AM', '2:00 PM', '6:00 PM'],
      'duration': '2-4 horas',
      'priceRange': '\$15,000 - \$30,000 COP',
      'packingTips': ['Documentos', 'Ropa cómoda', 'Snacks'],
      'attractions': ['Centro de la ciudad', 'Parques locales'],
      'safetyTips': ['Viajar de día', 'Usar empresas reconocidas'],
      'bestSeason': 'Todo el año',
      'additionalInfo': 'Ruta popular entre $origin y $destination'
    };
  }

  static Map<String, dynamic> _getFallbackSchedules() {
    return {
      'cheapestDays': ['Martes', 'Miércoles'],
      'bestAvailability': ['10:00 AM', '3:00 PM'],
      'lessTraffic': ['6:00 AM', '8:00 PM'],
      'alternativeDates': [
        {'date': 'Mañana', 'reason': 'Disponibilidad', 'savings': '10%'}
      ],
      'seasonalTips': 'Evitar temporadas altas',
      'flexibilityBenefits': 'Mejor disponibilidad y precios'
    };
  }

  static Map<String, dynamic> _getFallbackInnovativeSuggestions() {
    return {
      'scenicRoutes': ['Ruta principal'],
      'interestingStops': [
        {'place': 'Parada intermedia', 'activity': 'Descanso', 'duration': '15 min'}
      ],
      'localExperiences': ['Comida local'],
      'transportOptions': ['Bus directo'],
      'roadActivities': ['Descanso', 'Contemplar paisaje'],
      'foodRecommendations': ['Comida típica regional'],
      'accommodationIdeas': ['Hoteles locales'],
      'budgetTips': 'Comparar precios entre empresas'
    };
  }

  static Map<String, dynamic> _getFallbackPersonalizedRecommendations() {
    return {
      'detectedPreferences': ['Comodidad', 'Puntualidad'],
      'similarSuccessfulRoutes': ['Rutas directas'],
      'basedOnHistory': ['Mantener preferencias actuales'],
      'improvements': ['Explorar nuevas opciones'],
      'newExperiences': ['Probar diferentes horarios'],
      'personalizedTips': 'Continúa con tus preferencias habituales'
    };
  }
}