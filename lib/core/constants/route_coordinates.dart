// lib/core/constants/route_coordinates.dart
import 'package:latlong2/latlong.dart';

// --- 1. FUNCIÓN DE NORMALIZACIÓN MEJORADA ---
// Ahora maneja minúsculas, espacios y ELIMINA ACENTOS/TILDES
String _normalizeName(String name) {
  String normalized = name.toLowerCase().trim();
  
  // Eliminar acentos para máxima compatibilidad con las claves del mapa
  normalized = normalized.replaceAll('á', 'a');
  normalized = normalized.replaceAll('é', 'e');
  normalized = normalized.replaceAll('í', 'i');
  normalized = normalized.replaceAll('ó', 'o');
  normalized = normalized.replaceAll('ú', 'u');

  // Si su data usa 'San Juan de Pasto', esto lo convierte a 'san juan de pasto'
  return normalized;
}

// --- 2. MAPA DE COORDENADAS NORMALIZADO (CLAVES EN MINÚSCULAS Y SIN ACENTOS) ---
const Map<String, LatLng> NARINO_COORDINATES_NORMALIZED = {
  // 📍 CAPITALES Y CIUDADES GRANDES
  'pasto': LatLng(1.2066, -77.2796),
  'ipiales': LatLng(0.8290, -77.6366),
  'tumaco': LatLng(1.8058, -78.7525),
  'tuquerres': LatLng(1.0667, -77.6167),
  'la union': LatLng(1.5855, -76.9530),
  'buesaco': LatLng(1.3789, -77.1472),

  // ⛰️ MUNICIPIOS DE LA ZONA ANDINA Y CENTRO
  'samaniego': LatLng(1.3323, -77.3750),
  'cumbal': LatLng(0.9008, -77.7119),
  'aldana': LatLng(0.8667, -77.6833),
  'guaitarilla': LatLng(1.0877, -77.4647),
  'yacuanquer': LatLng(1.1097, -77.3697),
  'chachagui': LatLng(1.3999, -77.2667),
  'sandona': LatLng(1.2889, -77.3986),
  'consaca': LatLng(1.2833, -77.3200),
  'iles': LatLng(1.0333, -77.4667),
  'guachucal': LatLng(0.9667, -77.7167),

  // 🏞️ MUNICIPIOS ADICIONALES ZONA ANDINA/CENTRO
  'alban': LatLng(1.3142, -77.1972),
  'ancuya': LatLng(1.2633, -77.5150), // ⬅️ CORREGIDO (Normalizado)
  'arboleda': LatLng(1.5030, -77.1358),
  'berruecos': LatLng(1.5030, -77.1358), // ⬅️ NUEVO: Clave para la cabecera de Arboleda
  'belen': LatLng(1.6447, -77.0167),
  'colon': LatLng(1.6667, -76.9333),
  'contadero': LatLng(0.8833, -77.6333),
  'cordoba': LatLng(0.8333, -77.5667),
  'cuaspud': LatLng(0.8333, -77.6667),
  'el peñol': LatLng(1.4111, -77.3889),
  'el rosario': LatLng(1.6833, -77.0167),
  'el tablon de gomez': LatLng(1.4333, -77.1333),
  'funes': LatLng(1.3500, -77.2500),
  'genova': LatLng(1.4500, -77.0667),
  'gualmatan': LatLng(0.8833, -77.5997),
  'iscuande': LatLng(2.3500, -78.4333),
  'la florida': LatLng(1.3167, -77.3333),
  'leiva': LatLng(1.6833, -77.3833),
  'linares': LatLng(1.3500, -77.5000),
  'los andes': LatLng(1.5472, -77.3333),
  'mallama': LatLng(1.0850, -77.7550),
  'nariño': LatLng(1.6167, -77.0500),
  'potosi': LatLng(0.8500, -77.4167),
  'providencia': LatLng(1.5667, -77.0167),
  'puerres': LatLng(0.8833, -77.4333),
  'pupiales': LatLng(0.8525, -77.6075),
  'ricaurte': LatLng(1.0969, -77.9650),
  'roberto payan': LatLng(1.8500, -78.3667),
  'san bernardo': LatLng(1.6000, -77.2833),
  'san lorenzo': LatLng(1.5283, -77.0167),
  'san pablo': LatLng(1.5167, -76.9667),
  'san pedro de cartago': LatLng(1.4833, -77.1000),
  'santacruz': LatLng(1.4833, -77.1167),
  'sapuyes': LatLng(0.9667, -77.5000),
  'taminango': LatLng(1.5833, -77.1833),
  'tangua': LatLng(1.1167, -77.3000),
  'toledo': LatLng(1.5667, -77.0333),
  'policarpa': LatLng(1.5833, -77.4333),
  'el tambo': LatLng(1.2956, -77.5408),
  'la llanada': LatLng(1.3500, -77.4333),
  'cumbitara': LatLng(1.7000, -77.0000),
  'guachaves': LatLng(1.4833, -77.1167),

  // 🌴 MUNICIPIOS DE LA COSTA Y PIEDEMONTE
  'barbacoas': LatLng(1.6500, -78.1667),
  'el charco': LatLng(2.4833, -78.1167),
  'francisco pizarro': LatLng(2.6667, -78.5333),
  'olaya herrera': LatLng(2.6833, -78.2667),
  'santa barbara de iscuande': LatLng(2.2333, -78.5333),
  'la tola': LatLng(2.3333, -78.2667),
  'magui payan': LatLng(1.9833, -78.2167),
  'mosquera': LatLng(1.5833, -78.4167),

  // 🏞️ MUNICIPIOS DEL ORIENTE (Putumayo y límites)
  'mocoa': LatLng(1.1500, -76.6500),
  'la cruz': LatLng(1.6667, -76.8000),

};

// --- 3. FUNCIÓN DE UTILIDAD FINAL ---
LatLng getCoordinates(String townName) {
  // Normalizamos el nombre de entrada antes de la búsqueda.
  final normalizedKey = _normalizeName(townName);
  
  // Usamos el mapa normalizado para la búsqueda.
  return NARINO_COORDINATES_NORMALIZED[normalizedKey] ?? NARINO_COORDINATES_NORMALIZED['pasto']!; 
}