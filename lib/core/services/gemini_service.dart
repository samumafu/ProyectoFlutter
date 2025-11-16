// lib/core/services/gemini_service.dart (CORRECCIÓN FINAL - CON Content)

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 🚨 Reemplaza con tu clave API (o importa desde secrets.dart)
const String _geminiApiKey = 'AIzaSyBI8dg9XXfYqub47b7fxIvqMHT7oypZxWI'; 

class GeminiService {
  late final GenerativeModel _model;

  // Instrucción del sistema como String
  static const String _systemInstruction = 
      "Eres un amable y experto asistente de soporte virtual llamado 'Tu Flota IA'. Tu rol es asistir a pasajeros de una empresa de transporte en Nariño, Colombia. "
      "Responde preguntas sobre reservas, horarios, políticas de cancelación, o información turística de los municipios de Nariño (como Pasto, Ipiales, Tumaco, Túquerres, etc.). "
      "Mantén un tono profesional, servicial y conciso. NO puedes realizar reservas o cancelaciones por tu cuenta, solo dar indicaciones.";

  GeminiService() {
    // Convertimos la String de la instrucción del sistema a un objeto Content
    // para cumplir con el requisito del parámetro.
    final systemContent = Content.system(_systemInstruction); // ✅ CORRECCIÓN CLAVE
    
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', 
      apiKey: _geminiApiKey,
      
      // ✅ Pasamos el objeto Content.system() al parámetro systemInstruction
      systemInstruction: systemContent, 
    );
  }

  // Método para generar la respuesta
  Future<String> getResponse(String userMessage, List<Content> chatHistory) async {
    try {
      final userContent = Content.text(userMessage);
      final fullConversation = [...chatHistory, userContent];
      final response = await _model.generateContent(fullConversation);

      return response.text ?? 'Lo siento, no pude procesar tu solicitud. Intenta de nuevo.';
      
    } catch (e) {
      print('Error en la llamada a Gemini: $e');
      return 'Ocurrió un error de conexión con el asistente. Intenta más tarde.';
    }
  }
}

final geminiServiceProvider = Provider((ref) => GeminiService());