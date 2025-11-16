import 'dart:convert';

// ... (Clase CompanySchedule y Reservation OMITIDAS por brevedad, no necesitan cambio)

// --------------------------------------------------------------------------
// CLASE ChatMessage CORREGIDA
// --------------------------------------------------------------------------
class ChatMessage {
  final String id;
  final String tripId;
  final String senderId;
  final String message;
  // -> PROPIEDAD AÑADIDA PARA SOLUCIONAR EL ERROR DE COMPILACIÓN
  final DateTime? createdAt; 

  const ChatMessage({
    required this.id,
    required this.tripId,
    required this.senderId,
    required this.message,
    this.createdAt, // -> AÑADIDA AL CONSTRUCTOR
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      tripId: map['trip_id'] as String,
      senderId: map['sender_id'] as String,
      message: map['message'] as String,
      // -> LÓGICA AÑADIDA PARA PARSEAR EL TIMESTAMP
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'sender_id': senderId,
      'message': message,
      'created_at': createdAt?.toIso8601String(), // Opcional, para incluirlo al guardar
    };
  }
}