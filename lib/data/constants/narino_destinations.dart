class NarinoDestinations {
  static const List<String> municipalities = [
    // Ciudades principales
    'Pasto',
    'Ipiales', 
    'Túquerres',
    
    // Otros municipios importantes
    'Tumaco',
    'Barbacoas',
    'Samaniego',
    'La Unión',
    'Sandoná',
    'Consacá',
    'Yacuanquer',
    'Tangua',
    'Funes',
    'Guachucal',
    'Cumbal',
    'Aldana',
    'Potosí',
    'Gualmatán',
    'Contadero',
    'Córdoba',
    'Sapuyes',
    'Iles',
    'Pupiales',
    'Cuaspud',
    'Ricaurte',
    'Mallama',
    'Providencia',
    'Leiva',
    'Policarpa',
    'Cumbitara',
    'Los Andes',
    'La Cruz',
    'Belén',
    'San Bernardo',
    'Colón',
    'San Lorenzo',
    'Arboleda',
    'Buesaco',
    'Chachagüí',
    'El Tambo',
    'La Florida',
    'Nariño',
    'Ospina',
    'Francisco Pizarro',
    'Mosquera',
    'El Charco',
    'La Tola',
    'Olaya Herrera',
    'Santa Bárbara',
    'Magüí',
    'Roberto Payán',
    'Ancuyá',
    'Linares',
    'San Pablo',
    'Taminango',
    'San Pedro de Cartago',
    'El Rosario',
    'El Peñol',
    'El Tablón de Gómez',
    'La Llanada',
    'Imués',
    'Puerres',
    'Santacruz',
    'Guaitarilla',
    'Albán',
  ];

  static const Map<String, List<String>> regions = {
    'Norte': [
      'Ipiales', 'Aldana', 'Contadero', 'Córdoba', 
      'Cuaspud', 'Cumbal', 'Funes', 'Guachucal', 'Gualmatán', 
      'Iles', 'Potosí', 'Pupiales', 'Sapuyes', 'Túquerres'
    ],
    'Centro': [
      'Pasto', 'Buesaco', 'Chachagüí', 'Consacá', 'El Tambo', 
      'La Florida', 'Nariño', 'Sandoná', 'Tangua', 'Yacuanquer'
    ],
    'Sur': [
      'Ancuyá', 'Linares', 'San Pablo', 'Taminango', 'San Pedro de Cartago',
      'El Rosario', 'El Peñol', 'El Tablón de Gómez', 'La Llanada', 
      'Los Andes'
    ],
    'Occidente': [
      'Barbacoas', 'Cumbitara', 'La Cruz', 'La Unión', 'Leiva', 
      'Mallama', 'Policarpa', 'Ricaurte', 'Samaniego'
    ],
    'Pacífico': [
      'Tumaco', 'Barbacoas', 'El Charco', 'Francisco Pizarro', 
      'La Tola', 'Magüí', 'Mosquera', 'Olaya Herrera', 'Roberto Payán', 
      'Santa Bárbara'
    ],
    'Cordillera': [
      'Belén', 'Colón', 'San Bernardo', 'San Lorenzo', 'Arboleda',
      'Ospina', 'Imués', 'Puerres', 'Santacruz', 'Guaitarilla', 'Albán',
      'Providencia'
    ]
  };

  // Rutas populares estáticas (ahora se gestionan dinámicamente)
  static const List<Map<String, String>> popularRoutes = [
    {'origin': 'Pasto', 'destination': 'Ipiales'},
    {'origin': 'Pasto', 'destination': 'Túquerres'},
    {'origin': 'Pasto', 'destination': 'Tumaco'},
    {'origin': 'Ipiales', 'destination': 'Pasto'},
    {'origin': 'Túquerres', 'destination': 'Pasto'},
    {'origin': 'Tumaco', 'destination': 'Pasto'},
    {'origin': 'Pasto', 'destination': 'Tangua'},
    {'origin': 'Tangua', 'destination': 'Pasto'},
  ];

  static List<String> getDestinationsByRegion(String region) {
    return regions[region] ?? [];
  }

  static List<Map<String, String>> getPopularRoutesFrom(String origin) {
    return popularRoutes
        .where((route) => route['origin'] == origin)
        .toList();
  }

  static bool isValidDestination(String destination) {
    return municipalities.contains(destination);
  }

  static List<String> searchDestinations(String query) {
    if (query.isEmpty) return municipalities;
    
    return municipalities
        .where((destination) => 
            destination.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  static String getRegionForDestination(String destination) {
    for (final entry in regions.entries) {
      if (entry.value.contains(destination)) {
        return entry.key;
      }
    }
    return 'Desconocida';
  }
}