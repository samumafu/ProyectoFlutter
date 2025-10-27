import 'package:flutter/material.dart';
import '../services/ai_travel_service.dart';
import '../services/user_preferences_service.dart';

class PredictiveSearchWidget extends StatefulWidget {
  final Function(String origin, String destination)? onRouteSelected;
  final String? initialQuery;

  const PredictiveSearchWidget({
    Key? key,
    this.onRouteSelected,
    this.initialQuery,
  }) : super(key: key);

  @override
  State<PredictiveSearchWidget> createState() => _PredictiveSearchWidgetState();
}

class _PredictiveSearchWidgetState extends State<PredictiveSearchWidget>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final UserPreferencesService _prefsService = UserPreferencesService();
  final AITravelService _aiService = AITravelService();
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  List<Map<String, dynamic>> _predictions = [];
  List<Map<String, dynamic>> _smartSuggestions = [];
  bool _isLoading = false;
  bool _showPredictions = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    
    _loadSmartSuggestions();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _showPredictions = false;
        _predictions = [];
      });
      _animationController.reverse();
      return;
    }

    if (query.length >= 2) {
      _generatePredictions(query);
    }
  }

  Future<void> _loadSmartSuggestions() async {
    try {
      final personalizedData = await _prefsService.getPersonalizedData();
      final suggestions = await _generateSmartRouteSuggestions(personalizedData);
      
      setState(() {
        _smartSuggestions = suggestions;
      });
    } catch (e) {
      setState(() {
        _smartSuggestions = _getDefaultSuggestions();
      });
    }
  }

  Future<void> _generatePredictions(String query) async {
    setState(() => _isLoading = true);
    
    try {
      final personalizedData = await _prefsService.getPersonalizedData();
      final predictions = await _generateAIPredictions(query, personalizedData);
      
      setState(() {
        _predictions = predictions;
        _showPredictions = true;
        _isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      setState(() {
        _predictions = _getBasicPredictions(query);
        _showPredictions = true;
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  Future<List<Map<String, dynamic>>> _generateAIPredictions(
    String query, 
    Map<String, dynamic> personalizedData
  ) async {
    // Simulación de predicciones de IA basadas en el query y datos personalizados
    final predictions = <Map<String, dynamic>>[];
    
    final destinations = [
      'Pasto', 'Ipiales', 'Tumaco', 'Túquerres', 'Samaniego',
      'La Cruz', 'Barbacoas', 'Ricaurte', 'Cumbal', 'Aldana'
    ];
    
    final recentSearches = personalizedData['recentSearches'] as List<String>? ?? [];
    
    // Filtrar destinos que coincidan con el query
    final matchingDestinations = destinations
        .where((dest) => dest.toLowerCase().contains(query.toLowerCase()))
        .toList();
    
    // Agregar predicciones basadas en coincidencias
    for (final dest in matchingDestinations) {
      predictions.add({
        'type': 'destination',
        'text': dest,
        'confidence': _calculateConfidence(dest, query, recentSearches),
        'icon': Icons.place,
        'color': Colors.blue,
        'subtitle': 'Destino popular',
      });
    }
    
    // Agregar rutas sugeridas basadas en búsquedas recientes
    if (recentSearches.isNotEmpty) {
      for (final recent in recentSearches.take(3)) {
        if (recent.toLowerCase().contains(query.toLowerCase())) {
          predictions.add({
            'type': 'recent',
            'text': recent,
            'confidence': 90,
            'icon': Icons.history,
            'color': Colors.green,
            'subtitle': 'Búsqueda reciente',
          });
        }
      }
    }
    
    // Agregar sugerencias de rutas completas
    if (query.length >= 3) {
      predictions.addAll([
        {
          'type': 'route',
          'text': '$query → Pasto',
          'confidence': 85,
          'icon': Icons.route,
          'color': Colors.purple,
          'subtitle': 'Ruta sugerida',
        },
        {
          'type': 'route',
          'text': 'Pasto → $query',
          'confidence': 80,
          'icon': Icons.route,
          'color': Colors.purple,
          'subtitle': 'Ruta sugerida',
        },
      ]);
    }
    
    // Ordenar por confianza
    predictions.sort((a, b) => b['confidence'].compareTo(a['confidence']));
    
    return predictions.take(6).toList();
  }

  int _calculateConfidence(String destination, String query, List<String> recentSearches) {
    int confidence = 50;
    
    // Aumentar confianza si coincide exactamente
    if (destination.toLowerCase() == query.toLowerCase()) {
      confidence += 40;
    }
    
    // Aumentar confianza si está en búsquedas recientes
    if (recentSearches.contains(destination)) {
      confidence += 30;
    }
    
    // Aumentar confianza basada en la longitud de la coincidencia
    final matchLength = query.length;
    confidence += (matchLength * 5).clamp(0, 20);
    
    return confidence.clamp(0, 100);
  }

  List<Map<String, dynamic>> _getBasicPredictions(String query) {
    final destinations = [
      'Pasto', 'Ipiales', 'Tumaco', 'Túquerres', 'Samaniego',
      'La Cruz', 'Barbacoas', 'Ricaurte', 'Cumbal', 'Aldana'
    ];
    
    return destinations
        .where((dest) => dest.toLowerCase().contains(query.toLowerCase()))
        .map((dest) => {
              'type': 'destination',
              'text': dest,
              'confidence': 70,
              'icon': Icons.place,
              'color': Colors.blue,
              'subtitle': 'Destino',
            })
        .take(5)
        .toList();
  }

  Future<List<Map<String, dynamic>>> _generateSmartRouteSuggestions(
    Map<String, dynamic> personalizedData
  ) async {
    final suggestions = <Map<String, dynamic>>[];
    
    // Sugerencias basadas en el día de la semana
    final now = DateTime.now();
    if (now.weekday >= 5) { // Viernes, sábado, domingo
      suggestions.add({
        'type': 'weekend',
        'origin': 'Pasto',
        'destination': 'Tumaco',
        'title': 'Escapada de Fin de Semana',
        'subtitle': 'Perfecto para relajarse en la playa',
        'icon': Icons.beach_access,
        'color': Colors.cyan,
      });
    }
    
    // Sugerencias estacionales
    final month = now.month;
    if (month == 12 || month == 1) {
      suggestions.add({
        'type': 'seasonal',
        'origin': 'Pasto',
        'destination': 'Ipiales',
        'title': 'Temporada Navideña',
        'subtitle': 'Visita las celebraciones tradicionales',
        'icon': Icons.celebration,
        'color': Colors.red,
      });
    }
    
    // Sugerencias basadas en búsquedas recientes
    final recentSearches = personalizedData['recentSearches'] as List<String>? ?? [];
    if (recentSearches.isNotEmpty) {
      final mostSearched = recentSearches.first;
      suggestions.add({
        'type': 'frequent',
        'origin': 'Pasto',
        'destination': mostSearched,
        'title': 'Tu Ruta Favorita',
        'subtitle': 'Basado en tus búsquedas recientes',
        'icon': Icons.favorite,
        'color': Colors.pink,
      });
    }
    
    // Sugerencias de exploración
    suggestions.add({
      'type': 'exploration',
      'origin': 'Pasto',
      'destination': 'Samaniego',
      'title': 'Descubre Nuevos Lugares',
      'subtitle': 'Explora destinos menos conocidos',
      'icon': Icons.explore,
      'color': Colors.orange,
    });
    
    return suggestions;
  }

  List<Map<String, dynamic>> _getDefaultSuggestions() {
    return [
      {
        'type': 'popular',
        'origin': 'Pasto',
        'destination': 'Ipiales',
        'title': 'Ruta Popular',
        'subtitle': 'Conexión fronteriza más transitada',
        'icon': Icons.trending_up,
        'color': Colors.blue,
      },
      {
        'type': 'scenic',
        'origin': 'Pasto',
        'destination': 'Tumaco',
        'title': 'Ruta Escénica',
        'subtitle': 'Paisajes montañosos y costeros',
        'icon': Icons.landscape,
        'color': Colors.green,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchField(),
        if (_showPredictions) _buildPredictionsPanel(),
        if (!_showPredictions && _smartSuggestions.isNotEmpty) _buildSmartSuggestions(),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar destinos inteligentemente...',
          prefixIcon: const Icon(Icons.psychology, color: Colors.indigo),
          suffixIcon: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _showPredictions = false;
                          _predictions = [];
                        });
                      },
                    )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  Widget _buildPredictionsPanel() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.indigo, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Predicciones Inteligentes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ),
                ..._predictions.map((prediction) => _buildPredictionItem(prediction)).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPredictionItem(Map<String, dynamic> prediction) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: prediction['color'].withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          prediction['icon'],
          color: prediction['color'],
          size: 20,
        ),
      ),
      title: Text(
        prediction['text'],
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(prediction['subtitle']),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: prediction['color'],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${prediction['confidence']}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () => _handlePredictionTap(prediction),
    );
  }

  Widget _buildSmartSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Sugerencias Inteligentes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._smartSuggestions.map((suggestion) => _buildSuggestionCard(suggestion)).toList(),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: suggestion['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            suggestion['icon'],
            color: suggestion['color'],
            size: 24,
          ),
        ),
        title: Text(
          suggestion['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(suggestion['subtitle']),
            const SizedBox(height: 4),
            Text(
              '${suggestion['origin']} → ${suggestion['destination']}',
              style: TextStyle(
                color: suggestion['color'],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () => _handleSuggestionTap(suggestion),
      ),
    );
  }

  void _handlePredictionTap(Map<String, dynamic> prediction) {
    final text = prediction['text'] as String;
    
    if (prediction['type'] == 'route' && text.contains('→')) {
      final parts = text.split('→').map((e) => e.trim()).toList();
      if (parts.length == 2 && widget.onRouteSelected != null) {
        widget.onRouteSelected!(parts[0], parts[1]);
      }
    } else {
      _searchController.text = text;
      setState(() {
        _showPredictions = false;
        _predictions = [];
      });
    }
    
    // Guardar en búsquedas recientes
    _prefsService.addRecentSearch(text);
  }

  void _handleSuggestionTap(Map<String, dynamic> suggestion) {
    if (widget.onRouteSelected != null) {
      widget.onRouteSelected!(
        suggestion['origin'],
        suggestion['destination'],
      );
    }
    
    // Guardar en búsquedas recientes
    _prefsService.addRecentSearch('${suggestion['origin']} → ${suggestion['destination']}');
  }
}