import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService {
  static const String _recentSearchesKey = 'recent_searches';
  static const String _userIdKey = 'user_id';
  static const String _favoriteRoutesKey = 'favorite_routes';
  static const String _searchHistoryKey = 'search_history';
  static const String _aiPreferencesKey = 'ai_preferences';

  // Singleton pattern
  static final UserPreferencesService _instance = UserPreferencesService._internal();
  factory UserPreferencesService() => _instance;
  UserPreferencesService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // User ID management
  Future<void> setUserId(String userId) async {
    await init();
    await _prefs!.setString(_userIdKey, userId);
  }

  Future<String?> getUserId() async {
    await init();
    return _prefs!.getString(_userIdKey);
  }

  Future<void> clearUserId() async {
    await init();
    await _prefs!.remove(_userIdKey);
  }

  // Recent searches management (account-associated)
  Future<List<String>> getRecentSearches() async {
    await init();
    final userId = await getUserId();
    if (userId == null) return [];

    final key = '${_recentSearchesKey}_$userId';
    final searchesJson = _prefs!.getString(key);
    if (searchesJson == null) return [];

    try {
      final List<dynamic> searchesList = json.decode(searchesJson);
      return searchesList.cast<String>();
    } catch (e) {
      print('Error loading recent searches: $e');
      return [];
    }
  }

  Future<void> addRecentSearch(String cityName) async {
    await init();
    final userId = await getUserId();
    if (userId == null) return;

    final key = '${_recentSearchesKey}_$userId';
    List<String> searches = await getRecentSearches();
    
    // Remove if already exists to avoid duplicates
    searches.remove(cityName);
    
    // Add to the beginning
    searches.insert(0, cityName);
    
    // Keep only the last 10 searches
    if (searches.length > 10) {
      searches = searches.take(10).toList();
    }

    await _prefs!.setString(key, json.encode(searches));
  }

  Future<void> clearRecentSearches() async {
    await init();
    final userId = await getUserId();
    if (userId == null) return;

    final key = '${_recentSearchesKey}_$userId';
    await _prefs!.remove(key);
  }

  // Favorite routes management
  Future<List<Map<String, dynamic>>> getFavoriteRoutes() async {
    await init();
    final userId = await getUserId();
    if (userId == null) return [];

    final key = '${_favoriteRoutesKey}_$userId';
    final routesJson = _prefs!.getString(key);
    if (routesJson == null) return [];

    try {
      final List<dynamic> routesList = json.decode(routesJson);
      return routesList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error loading favorite routes: $e');
      return [];
    }
  }

  Future<void> addFavoriteRoute(Map<String, dynamic> route) async {
    await init();
    final userId = await getUserId();
    if (userId == null) return;

    final key = '${_favoriteRoutesKey}_$userId';
    List<Map<String, dynamic>> routes = await getFavoriteRoutes();
    
    // Check if route already exists
    final existingIndex = routes.indexWhere((r) => 
      r['origin'] == route['origin'] && r['destination'] == route['destination']);
    
    if (existingIndex != -1) {
      // Update existing route
      routes[existingIndex] = route;
    } else {
      // Add new route
      routes.insert(0, route);
    }

    // Keep only the last 20 favorite routes
    if (routes.length > 20) {
      routes = routes.take(20).toList();
    }

    await _prefs!.setString(key, json.encode(routes));
  }

  Future<void> removeFavoriteRoute(String origin, String destination) async {
    await init();
    final userId = await getUserId();
    if (userId == null) return;

    final key = '${_favoriteRoutesKey}_$userId';
    List<Map<String, dynamic>> routes = await getFavoriteRoutes();
    
    routes.removeWhere((route) => 
      route['origin'] == origin && route['destination'] == destination);

    await _prefs!.setString(key, json.encode(routes));
  }

  // Search history with metadata
  Future<List<Map<String, dynamic>>> getSearchHistory() async {
    await init();
    final userId = await getUserId();
    if (userId == null) return [];

    final key = '${_searchHistoryKey}_$userId';
    final historyJson = _prefs!.getString(key);
    if (historyJson == null) return [];

    try {
      final List<dynamic> historyList = json.decode(historyJson);
      return historyList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error loading search history: $e');
      return [];
    }
  }

  Future<void> addSearchHistory(Map<String, dynamic> searchData) async {
    await init();
    final userId = await getUserId();
    if (userId == null) return;

    final key = '${_searchHistoryKey}_$userId';
    List<Map<String, dynamic>> history = await getSearchHistory();
    
    // Add timestamp
    searchData['timestamp'] = DateTime.now().toIso8601String();
    
    // Add to the beginning
    history.insert(0, searchData);
    
    // Keep only the last 50 searches
    if (history.length > 50) {
      history = history.take(50).toList();
    }

    await _prefs!.setString(key, json.encode(history));
  }

  // AI preferences
  Future<Map<String, dynamic>> getAIPreferences() async {
    await init();
    final userId = await getUserId();
    if (userId == null) return {};

    final key = '${_aiPreferencesKey}_$userId';
    final prefsJson = _prefs!.getString(key);
    if (prefsJson == null) return {};

    try {
      return json.decode(prefsJson);
    } catch (e) {
      print('Error loading AI preferences: $e');
      return {};
    }
  }

  Future<void> updateAIPreferences(Map<String, dynamic> preferences) async {
    await init();
    final userId = await getUserId();
    if (userId == null) return;

    final key = '${_aiPreferencesKey}_$userId';
    await _prefs!.setString(key, json.encode(preferences));
  }

  // Travel preferences for AI recommendations
  Future<void> updateTravelPreferences({
    String? preferredTimeOfDay,
    List<String>? preferredDays,
    String? budgetRange,
    List<String>? interests,
    bool? flexibleSchedule,
  }) async {
    final currentPrefs = await getAIPreferences();
    
    if (preferredTimeOfDay != null) currentPrefs['preferredTimeOfDay'] = preferredTimeOfDay;
    if (preferredDays != null) currentPrefs['preferredDays'] = preferredDays;
    if (budgetRange != null) currentPrefs['budgetRange'] = budgetRange;
    if (interests != null) currentPrefs['interests'] = interests;
    if (flexibleSchedule != null) currentPrefs['flexibleSchedule'] = flexibleSchedule;

    await updateAIPreferences(currentPrefs);
  }

  // Get personalized data for AI
  Future<Map<String, dynamic>> getPersonalizedData() async {
    final recentSearches = await getRecentSearches();
    final favoriteRoutes = await getFavoriteRoutes();
    final searchHistory = await getSearchHistory();
    final aiPreferences = await getAIPreferences();

    return {
      'recentSearches': recentSearches,
      'favoriteRoutes': favoriteRoutes,
      'searchHistory': searchHistory,
      'aiPreferences': aiPreferences,
      'mostSearchedOrigins': _getMostSearchedCities(searchHistory, 'origin'),
      'mostSearchedDestinations': _getMostSearchedCities(searchHistory, 'destination'),
      'preferredTravelDays': _getPreferredTravelDays(searchHistory),
    };
  }

  List<String> _getMostSearchedCities(List<Map<String, dynamic>> history, String field) {
    final cityCount = <String, int>{};
    
    for (final search in history) {
      final city = search[field] as String?;
      if (city != null) {
        cityCount[city] = (cityCount[city] ?? 0) + 1;
      }
    }

    final sortedCities = cityCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCities.take(5).map((e) => e.key).toList();
  }

  List<String> _getPreferredTravelDays(List<Map<String, dynamic>> history) {
    final dayCount = <String, int>{};
    
    for (final search in history) {
      final dateStr = search['departureDate'] as String?;
      if (dateStr != null) {
        try {
          final date = DateTime.parse(dateStr);
          final dayName = _getDayName(date.weekday);
          dayCount[dayName] = (dayCount[dayName] ?? 0) + 1;
        } catch (e) {
          // Ignore invalid dates
        }
      }
    }

    final sortedDays = dayCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedDays.take(3).map((e) => e.key).toList();
  }

  String _getDayName(int weekday) {
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return days[weekday - 1];
  }

  // Clear all user data (for logout)
  Future<void> clearAllUserData() async {
    await init();
    final userId = await getUserId();
    if (userId == null) return;

    final keys = [
      '${_recentSearchesKey}_$userId',
      '${_favoriteRoutesKey}_$userId',
      '${_searchHistoryKey}_$userId',
      '${_aiPreferencesKey}_$userId',
    ];

    for (final key in keys) {
      await _prefs!.remove(key);
    }

    await clearUserId();
  }
}