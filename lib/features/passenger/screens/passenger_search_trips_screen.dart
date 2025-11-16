import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/core/services/supabase_service.dart';
import 'package:tu_flota/features/passenger/controllers/passenger_controller.dart';
import 'package:tu_flota/features/passenger/widgets/passenger_trip_card.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';

// Definiciones de estilo para el diseño, inspiradas en Despegar
const Color _despegarPrimaryBlue = Color(0xFF0073E6); // Azul vibrante de Despegar
const Color _despegarLightBlue = Color(0xFFE6F3FF); // Azul muy claro para fondos
const Color _despegarDarkText = Color(0xFF333333); // Texto oscuro
const Color _despegarGreyText = Color(0xFF666666); // Texto gris
const Color _despegarBackgroundColor = Color(0xFFF8F9FA); // Fondo casi blanco
const double _maxContentWidth = 900.0; // Constante global para centrar contenido en web

class PassengerSearchTripsScreen extends ConsumerStatefulWidget {
  const PassengerSearchTripsScreen({super.key});

  @override
  ConsumerState<PassengerSearchTripsScreen> createState() => _PassengerSearchTripsScreenState();
}

class _PassengerSearchTripsScreenState extends ConsumerState<PassengerSearchTripsScreen> {
  String? _selectedOrigin;
  String? _selectedDestination;

  final _originCtrl = TextEditingController(); 
  final _destinationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(passengerControllerProvider.notifier).loadMunicipalities());
    Future.microtask(() => ref.read(passengerControllerProvider.notifier).loadAllTrips());
    Future.microtask(() => ref.read(passengerControllerProvider.notifier).loadMyReservations());
  }

  @override
  void dispose() {
    _originCtrl.dispose();
    _destinationCtrl.dispose();
    super.dispose();
  }

  void _search() {
    final origin = _selectedOrigin ?? _originCtrl.text;
    final destination = _selectedDestination ?? _destinationCtrl.text;
    
    ref
        .read(passengerControllerProvider.notifier)
        .searchTrips(origin: origin, destination: destination);
  }

  void _navigateToHistory() {
    Navigator.pushNamed(context, '/passenger/history');
  }

  // Widget de Dropdown de Municipio (adaptado al nuevo estilo y corregido el error de aserción)
  Widget _buildMunicipalityDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    required List<String> items,
  }) {
    // Lógica para manejar el valor inicial (value) vs items y evitar el error de aserción.
    final hasRealItems = items.length > 1 || (items.length == 1 && items.first != 'Cargando...');
    final effectiveItems = hasRealItems ? items : <String>[];
    
    // Si el valor seleccionado NO está en la lista actual de municipios, forzamos a null.
    final effectiveValue = (value != null && hasRealItems && effectiveItems.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      value: effectiveValue, // Usar el valor verificado
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _despegarGreyText, fontSize: 14),
        prefixIcon: Icon(label == AppStrings.origin ? Icons.location_on : Icons.pin_drop, color: _despegarPrimaryBlue.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          // Se quita 'const' de BorderSide porque Colors.grey.shade300 no es constante
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1), 
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _despegarPrimaryBlue, width: 2),
        ),
      ),
      hint: Text(items.isEmpty || items.first == 'Cargando...' ? 'Cargando...' : 'Selecciona $label'),
      items: effectiveItems.map((String muni) {
        return DropdownMenuItem<String>(
          value: muni,
          child: Text(muni, style: const TextStyle(color: _despegarDarkText)),
        );
      }).toList(),
      onChanged: hasRealItems ? onChanged : null,
      dropdownColor: Colors.white,
      iconEnabledColor: _despegarPrimaryBlue,
    );
  }

  // Widget para el formulario de búsqueda principal (rediseñado al estilo Despegar)
  Widget _buildSearchForm(BuildContext context, bool isNarrow, List<String> availableMunicipalities) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _despegarPrimaryBlue.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _despegarLightBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_bus, color: _despegarPrimaryBlue.withOpacity(0.8), size: 20),
                const SizedBox(width: 8),
                const Text('Viajes en Bus', style: TextStyle(color: _despegarPrimaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildMunicipalityDropdown(
            label: AppStrings.origin,
            value: _selectedOrigin,
            items: availableMunicipalities,
            onChanged: (v) => setState(() => _selectedOrigin = v),
          ),
          const SizedBox(height: 15),
          _buildMunicipalityDropdown(
            label: AppStrings.destination,
            value: _selectedDestination,
            items: availableMunicipalities,
            onChanged: (v) => setState(() => _selectedDestination = v),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _search,
            icon: const Icon(Icons.search),
            label: const Text(AppStrings.search, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _despegarPrimaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 5,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para la sección de "Ciudades Populares"
  Widget _buildPopularCitiesSection(BuildContext context, bool isNarrow) {
    final List<String> popularCities = ['Pasto', 'Ipiales', 'Tumaco', 'Túquerres'];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16.0 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Text(
            'Ciudades más visitadas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: _despegarDarkText,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: popularCities.length,
              itemBuilder: (context, index) {
                final city = popularCities[index];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDestination = city);
                    _search();
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Buscando viajes a $city...')),
                    );
                  },
                  child: Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_city,
                          size: 40,
                          color: _despegarPrimaryBlue.withOpacity(0.7),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          city,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _despegarDarkText,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Ver viajes',
                          style: TextStyle(color: _despegarPrimaryBlue, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // **********************************************
  // 🚀 Nuevas funciones para la Sección de Viajes
  // **********************************************

  // Encabezado de la Sección de Viajes
  Widget _buildTripsSectionHeader(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _despegarLightBlue, width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.departure_board_outlined, color: _despegarPrimaryBlue, size: 24),
            const SizedBox(width: 10),
            Text(
              'Resultados de la Búsqueda',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _despegarPrimaryBlue,
              ),
            ),
            const Spacer(),
            Icon(Icons.filter_list, color: _despegarGreyText),
          ],
        ),
      ),
    );
  }

  // Simulación de Carga (Skeletor)
  Widget _buildLoadingSkeletons(bool isNarrow) {
    return Column(
      children: List.generate(3, (index) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            height: isNarrow ? 120 : 150, // Altura de la tarjeta
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const LinearProgressIndicator(color: _despegarLightBlue, backgroundColor: Colors.white)
          ),
        )
      ),
    );
  }

  // Mensaje cuando no hay viajes
  Widget _buildNoTripsFound(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bus_alert, size: 70, color: _despegarGreyText.withOpacity(0.5)),
            const SizedBox(height: 15),
            Text(
              '¡Vaya! No encontramos viajes.', 
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: _despegarDarkText, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 5),
            Text(
              'Intenta buscar en otro día o ruta, o recarga la página.', 
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _despegarGreyText)
            ),
          ],
        ),
      ),
    );
  }

  // Lista de viajes (reestructura la presentación)
  Widget _buildTripsList(BuildContext context, List<CompanySchedule> trips) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: trips.length,
      padding: EdgeInsets.zero,
      itemBuilder: (ctx, i) {
        final CompanySchedule s = trips[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 15.0), // Espacio un poco mayor entre tarjetas
          child: PassengerTripCard(
            schedule: s,
            onOpen: () {
              Navigator.pushNamed(
                context,
                '/passenger/trip/detail',
                arguments: s,
              );
            },
          ),
        );
      },
    );
  }

  // 🚀 MEJORA DE DISEÑO: Sección de Próximos Viajes (función contenedora)
  Widget _buildTripsSection(BuildContext context, List<CompanySchedule> trips, bool isNarrow, bool isLoading, String? error) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16.0 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          
          // Título destacado
          _buildTripsSectionHeader(context),
          
          const SizedBox(height: 15),

          // Manejo de Error
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Error: ${error}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),

          // Contenido de la Lista: Carga, Vacío o Resultados
          if (isLoading) 
            _buildLoadingSkeletons(isNarrow) 
          else if (trips.isEmpty)
            _buildNoTripsFound(context) 
          else 
            _buildTripsList(context, trips),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passengerControllerProvider);
    final trips = state.trips;
    
    final availableMunicipalities = state.municipalities.isEmpty
                                      ? ['Cargando...'] 
                                      : state.municipalities;

    return Scaffold(
      backgroundColor: _despegarBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.bus_alert, color: _despegarPrimaryBlue),
            const SizedBox(width: 8),
            Text('Tu Flota', style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _despegarDarkText, 
              fontWeight: FontWeight.bold
            )),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: _despegarPrimaryBlue),
            tooltip: 'Historial de Reservas',
            onPressed: _navigateToHistory,
          ),
          IconButton(
            icon: const Icon(Icons.person, color: _despegarPrimaryBlue),
            tooltip: 'Mi Perfil',
            onPressed: () => Navigator.pushNamed(context, '/passenger/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: _despegarGreyText),
            tooltip: AppStrings.signOut,
            onPressed: () async {
              await SupabaseService().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/auth/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            final horizontalPadding = (constraints.maxWidth - _maxContentWidth).clamp(0.0, double.infinity) / 2;

            return SingleChildScrollView( 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Área superior (Banner Azul Claro)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 40, bottom: 90, left: 24, right: 24),
                    color: _despegarLightBlue,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '¡Tu Flota, tu destino!',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: _despegarPrimaryBlue,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // 2. Formulario de Búsqueda Flotante y Mensaje
                  Transform.translate(
                    offset: const Offset(0, -50), // Subir el formulario para superponerlo
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Mensaje visible justo encima de la tarjeta flotante
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: isNarrow ? 24.0 : horizontalPadding + 16),
                          child: const Text(
                            'Busca y reserva tus viajes en bus de manera sencilla y rápida.',
                            style: TextStyle(color: _despegarDarkText, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Tarjeta de Búsqueda
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: _buildSearchForm(context, isNarrow, availableMunicipalities),
                        ),
                      ],
                    ),
                  ),
                  
                  // 3. Sección de ciudades populares
                  _buildPopularCitiesSection(context, isNarrow),
                  
                  // 4. Sección de Próximos Viajes (MEJORADA)
                  _buildTripsSection(
                    context, 
                    trips, 
                    isNarrow, 
                    state.isLoading, 
                    state.error
                  ),
                ],
              ),
            );
          },
        ),
      ),
      
      // 🚀 AÑADIR EL FLOATING ACTION BUTTON AQUÍ
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navegar a la pantalla del asistente de chat
          // Asegúrate de que '/passenger/chat-assistant' esté definido en tus rutas.
          Navigator.pushNamed(context, '/passenger/chat-assistant');
        },
        label: const Text("Tu Flota IA"),
        icon: const Icon(Icons.chat_bubble_outline),
        backgroundColor: _despegarPrimaryBlue,
        foregroundColor: Colors.white,
        tooltip: 'Asistente Virtual',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}