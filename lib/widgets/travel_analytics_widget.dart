import 'package:flutter/material.dart';
import '../services/user_preferences_service.dart';
import '../services/ai_travel_service.dart';

class TravelAnalyticsWidget extends StatefulWidget {
  const TravelAnalyticsWidget({Key? key}) : super(key: key);

  @override
  State<TravelAnalyticsWidget> createState() => _TravelAnalyticsWidgetState();
}

class _TravelAnalyticsWidgetState extends State<TravelAnalyticsWidget>
    with TickerProviderStateMixin {
  final UserPreferencesService _prefsService = UserPreferencesService();
  final AITravelService _aiService = AITravelService();
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _insights = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _loadAnalytics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    try {
      final personalizedData = await _prefsService.getPersonalizedData();
      final analytics = await _generateTravelAnalytics(personalizedData);
      final insights = await _generateTravelInsights(personalizedData);
      
      setState(() {
        _analytics = analytics;
        _insights = insights;
        _isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _analytics = _getDefaultAnalytics();
        _insights = _getDefaultInsights();
      });
      _animationController.forward();
    }
  }

  Future<Map<String, dynamic>> _generateTravelAnalytics(Map<String, dynamic> data) async {
    final recentSearches = data['recentSearches'] as List<String>? ?? [];
    final favoriteRoutes = data['favoriteRoutes'] as List<String>? ?? [];
    
    return {
      'totalSearches': recentSearches.length,
      'favoriteDestinations': _getMostFrequentDestinations(recentSearches),
      'travelPattern': _analyzeTravelPattern(recentSearches),
      'preferredDays': _getPreferredTravelDays(),
      'budgetRange': _estimateBudgetRange(favoriteRoutes),
      'seasonalPreference': _getSeasonalPreference(),
    };
  }

  Future<List<Map<String, dynamic>>> _generateTravelInsights(Map<String, dynamic> data) async {
    return [
      {
        'title': 'Patrón de Viaje',
        'description': 'Prefieres viajes cortos los fines de semana',
        'icon': Icons.trending_up,
        'color': Colors.blue,
        'confidence': 85,
      },
      {
        'title': 'Destino Favorito',
        'description': 'Pasto es tu destino más buscado',
        'icon': Icons.favorite,
        'color': Colors.red,
        'confidence': 92,
      },
      {
        'title': 'Mejor Momento',
        'description': 'Los viernes por la tarde son ideales para ti',
        'icon': Icons.schedule,
        'color': Colors.green,
        'confidence': 78,
      },
      {
        'title': 'Ahorro Potencial',
        'description': 'Podrías ahorrar 15% reservando con anticipación',
        'icon': Icons.savings,
        'color': Colors.orange,
        'confidence': 88,
      },
    ];
  }

  List<String> _getMostFrequentDestinations(List<String> searches) {
    final frequency = <String, int>{};
    for (final search in searches) {
      frequency[search] = (frequency[search] ?? 0) + 1;
    }
    
    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(3).map((e) => e.key).toList();
  }

  String _analyzeTravelPattern(List<String> searches) {
    if (searches.length < 3) return 'Explorador ocasional';
    if (searches.length < 10) return 'Viajero regular';
    return 'Viajero frecuente';
  }

  List<String> _getPreferredTravelDays() {
    return ['Viernes', 'Sábado', 'Domingo'];
  }

  String _estimateBudgetRange(List<String> routes) {
    return '\$50,000 - \$150,000 COP';
  }

  String _getSeasonalPreference() {
    return 'Temporada seca (Diciembre - Marzo)';
  }

  Map<String, dynamic> _getDefaultAnalytics() {
    return {
      'totalSearches': 0,
      'favoriteDestinations': <String>[],
      'travelPattern': 'Nuevo usuario',
      'preferredDays': ['Viernes', 'Sábado'],
      'budgetRange': '\$30,000 - \$100,000 COP',
      'seasonalPreference': 'Todo el año',
    };
  }

  List<Map<String, dynamic>> _getDefaultInsights() {
    return [
      {
        'title': 'Bienvenido',
        'description': 'Comienza a buscar para obtener insights personalizados',
        'icon': Icons.explore,
        'color': Colors.blue,
        'confidence': 100,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis de Viajes'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_slideAnimation.value * MediaQuery.of(context).size.width, 0),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAnalyticsOverview(),
                        const SizedBox(height: 24),
                        _buildInsightsSection(),
                        const SizedBox(height: 24),
                        _buildRecommendationsSection(),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAnalyticsOverview() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.deepPurple, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Resumen de Actividad',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildAnalyticsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildAnalyticsCard(
          'Búsquedas Totales',
          '${_analytics['totalSearches']}',
          Icons.search,
          Colors.blue,
        ),
        _buildAnalyticsCard(
          'Patrón de Viaje',
          _analytics['travelPattern'],
          Icons.trending_up,
          Colors.green,
        ),
        _buildAnalyticsCard(
          'Rango de Presupuesto',
          _analytics['budgetRange'],
          Icons.attach_money,
          Colors.orange,
        ),
        _buildAnalyticsCard(
          'Preferencia Estacional',
          _analytics['seasonalPreference'],
          Icons.wb_sunny,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Insights Inteligentes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._insights.map((insight) => _buildInsightCard(insight)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: insight['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: insight['color'].withOpacity(0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: insight['color'],
          child: Icon(insight['icon'], color: Colors.white, size: 20),
        ),
        title: Text(
          insight['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(insight['description']),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: insight['color'],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${insight['confidence']}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.recommend, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Recomendaciones Personalizadas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRecommendationCard(
              'Mejor Momento para Viajar',
              'Basado en tu historial, los viernes por la tarde ofrecen mejores precios y disponibilidad.',
              Icons.schedule,
              Colors.blue,
            ),
            _buildRecommendationCard(
              'Destinos Sugeridos',
              'Considera explorar Ipiales y Tumaco, similares a tus búsquedas anteriores.',
              Icons.place,
              Colors.red,
            ),
            _buildRecommendationCard(
              'Ahorro Inteligente',
              'Reserva con 2 semanas de anticipación para obtener hasta 20% de descuento.',
              Icons.savings,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}