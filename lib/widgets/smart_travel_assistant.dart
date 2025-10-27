import 'package:flutter/material.dart';
import '../services/ai_travel_service.dart';
import '../services/user_preferences_service.dart';
import '../features/passenger/screens/ticket_search_screen.dart';
import 'travel_analytics_widget.dart';

class SmartTravelAssistant extends StatefulWidget {
  const SmartTravelAssistant({Key? key}) : super(key: key);

  @override
  State<SmartTravelAssistant> createState() => _SmartTravelAssistantState();
}

class _SmartTravelAssistantState extends State<SmartTravelAssistant>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final UserPreferencesService _prefsService = UserPreferencesService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _suggestions = [];
  String _currentMode = 'suggestions'; // suggestions, preferences, insights

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadSmartSuggestions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSmartSuggestions() async {
    setState(() => _isLoading = true);
    
    try {
      final personalizedData = await _prefsService.getPersonalizedData();
      final suggestions = await _generateSmartSuggestions(personalizedData);
      
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading smart suggestions: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _generateSmartSuggestions(
      Map<String, dynamic> personalizedData) async {
    final suggestions = <Map<String, dynamic>>[];
    
    // Sugerencias basadas en búsquedas recientes
    final recentSearches = personalizedData['recentSearches'] as List<dynamic>? ?? [];
    if (recentSearches.isNotEmpty) {
      suggestions.add({
        'type': 'recent_route',
        'title': 'Ruta Frecuente',
        'description': 'Basado en tus búsquedas recientes',
        'route': '${recentSearches.first} → Destinos populares',
        'icon': Icons.history,
        'color': Colors.blue,
        'action': 'search_similar',
      });
    }

    // Sugerencias de rutas populares en fechas específicas
    final now = DateTime.now();
    final isWeekend = now.weekday >= 6;
    
    if (isWeekend) {
      suggestions.add({
        'type': 'weekend_special',
        'title': 'Escapada de Fin de Semana',
        'description': 'Destinos perfectos para relajarse',
        'route': 'Pasto → Laguna de la Cocha',
        'icon': Icons.weekend,
        'color': Colors.green,
        'action': 'weekend_routes',
      });
    }

    // Sugerencias estacionales
    final month = now.month;
    if (month >= 12 || month <= 2) {
      suggestions.add({
        'type': 'seasonal',
        'title': 'Temporada Navideña',
        'description': 'Rutas populares en diciembre y enero',
        'route': 'Conecta con familia y tradiciones',
        'icon': Icons.celebration,
        'color': Colors.red,
        'action': 'seasonal_routes',
      });
    }

    // Sugerencias de ahorro
    suggestions.add({
      'type': 'savings',
      'title': 'Viajes Económicos',
      'description': 'Encuentra las mejores ofertas',
      'route': 'Rutas con descuentos disponibles',
      'icon': Icons.savings,
      'color': Colors.orange,
      'action': 'budget_routes',
    });

    // Sugerencias de exploración
    suggestions.add({
      'type': 'exploration',
      'title': 'Descubre Nuevos Destinos',
      'description': 'Lugares que aún no has visitado',
      'route': 'Aventuras por descubrir',
      'icon': Icons.explore,
      'color': Colors.purple,
      'action': 'explore_new',
    });

    return suggestions;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildModeSelector(),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Asistente Inteligente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Recomendaciones personalizadas con IA',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadSmartSuggestions,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildModeButton('suggestions', 'Sugerencias', Icons.lightbulb),
          const SizedBox(width: 8),
          _buildModeButton('preferences', 'Preferencias', Icons.tune),
          const SizedBox(width: 8),
          _buildModeButton('insights', 'Análisis', Icons.analytics),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode, String label, IconData icon) {
    final isSelected = _currentMode == mode;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.indigo : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildContentForMode(),
    );
  }

  Widget _buildContentForMode() {
    switch (_currentMode) {
      case 'suggestions':
        return _buildSuggestionsContent();
      case 'preferences':
        return _buildPreferencesContent();
      case 'insights':
        return _buildInsightsContent();
      default:
        return _buildSuggestionsContent();
    }
  }

  Widget _buildSuggestionsContent() {
    if (_isLoading) {
      return Container(
        height: 200,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generando sugerencias inteligentes...'),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _suggestions.map((suggestion) => _buildSuggestionCard(suggestion)).toList(),
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _handleSuggestionTap(suggestion),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (suggestion['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      suggestion['icon'] as IconData,
                      color: suggestion['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion['title'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          suggestion['description'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          suggestion['route'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: suggestion['color'] as Color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPreferenceItem(
            'Horario Preferido',
            'Mañana (6:00 - 12:00)',
            Icons.schedule,
            Colors.blue,
          ),
          _buildPreferenceItem(
            'Presupuesto',
            'Económico (\$20,000 - \$50,000)',
            Icons.attach_money,
            Colors.green,
          ),
          _buildPreferenceItem(
            'Tipo de Viaje',
            'Trabajo y Turismo',
            Icons.business_center,
            Colors.orange,
          ),
          _buildPreferenceItem(
            'Notificaciones',
            'Ofertas y Promociones',
            Icons.notifications,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(value),
        trailing: const Icon(Icons.edit, size: 20),
        onTap: () {
          // Implementar edición de preferencias
        },
      ),
    );
  }

  Widget _buildInsightsContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.indigo, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Análisis Detallado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Obtén insights profundos sobre tus patrones de viaje, preferencias y oportunidades de ahorro.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TravelAnalyticsWidget(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bar_chart),
                      label: const Text('Ver Análisis Completo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            'Rutas Más Buscadas',
            'Pasto → Ipiales (45%)',
            Icons.trending_up,
            Colors.blue,
            '↑ 12% esta semana',
          ),
          _buildInsightCard(
            'Día Preferido',
            'Viernes (32%)',
            Icons.calendar_today,
            Colors.green,
            'Mejor disponibilidad',
          ),
          _buildInsightCard(
            'Ahorro Promedio',
            '\$15,000 por viaje',
            Icons.savings,
            Colors.orange,
            'Con reserva anticipada',
          ),
          _buildInsightCard(
            'Tiempo de Viaje',
            '2.5 horas promedio',
            Icons.access_time,
            Colors.purple,
            'Rutas más eficientes',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSuggestionTap(Map<String, dynamic> suggestion) {
    final action = suggestion['action'] as String;
    
    switch (action) {
      case 'search_similar':
        _navigateToSearch('Pasto', '');
        break;
      case 'weekend_routes':
        _navigateToSearch('Pasto', 'Laguna de la Cocha');
        break;
      case 'seasonal_routes':
        _navigateToSearch('Pasto', 'Ipiales');
        break;
      case 'budget_routes':
        _navigateToSearch('Pasto', 'Túquerres');
        break;
      case 'explore_new':
        _navigateToSearch('Pasto', 'Tumaco');
        break;
    }
  }

  void _navigateToSearch(String origin, String destination) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketSearchScreen(
          initialOrigin: origin,
          initialDestination: destination,
        ),
      ),
    );
  }
}