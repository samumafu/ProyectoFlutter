import 'package:flutter/material.dart';
import '../data/constants/narino_destinations.dart';
import '../services/route_service.dart';

class SimpleCitySelector extends StatefulWidget {
  final String label;
  final String? initialValue;
  final Function(String cityName) onCitySelected;

  const SimpleCitySelector({
    Key? key,
    required this.label,
    this.initialValue,
    required this.onCitySelected,
  }) : super(key: key);

  @override
  State<SimpleCitySelector> createState() => _SimpleCitySelectorState();
}

class _SimpleCitySelectorState extends State<SimpleCitySelector> {
  String? _selectedCity;
  List<String> _availableCities = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialValue;
    _loadAvailableCities();
  }

  Future<void> _loadAvailableCities() async {
    setState(() => _isLoading = true);
    
    try {
      // Obtener ciudades dinámicamente desde Supabase
      final cities = await RouteService.getAllCities();
      
      // Si no hay ciudades en Supabase, usar las predeterminadas
      if (cities.isEmpty) {
        setState(() {
          _availableCities = NarinoDestinations.municipalities;
          _isLoading = false;
        });
      } else {
        setState(() {
          _availableCities = cities;
          _isLoading = false;
        });
      }
    } catch (e) {
      // En caso de error, usar las ciudades predeterminadas
      setState(() {
        _availableCities = NarinoDestinations.municipalities;
        _isLoading = false;
      });
      print('Error cargando ciudades: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showCityPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: _selectedCity != null ? Colors.indigo : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLoading
                        ? 'Cargando ciudades...'
                        : _selectedCity ?? 'Seleccionar ${widget.label.toLowerCase()}',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedCity != null ? Colors.black87 : Colors.grey.shade500,
                      fontWeight: _selectedCity != null ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.arrow_drop_down,
                color: Colors.grey.shade600,
              ),
          ],
        ),
      ),
    );
  }

  void _showCityPicker() {
    if (_isLoading) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Seleccionar ${widget.label}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _availableCities.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No hay destinos disponibles',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Las empresas deben crear rutas primero',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _availableCities.length,
                      itemBuilder: (context, index) {
                        final city = _availableCities[index];
                        final isSelected = city == _selectedCity;
                        
                        return ListTile(
                          leading: Icon(
                            Icons.location_city,
                            color: isSelected ? Colors.indigo : Colors.grey,
                          ),
                          title: Text(
                            city,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.indigo : Colors.black87,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: Colors.indigo)
                              : null,
                          onTap: () {
                            setState(() => _selectedCity = city);
                            widget.onCitySelected(city);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}