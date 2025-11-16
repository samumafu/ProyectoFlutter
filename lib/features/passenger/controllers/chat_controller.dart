// lib/features/passenger/controllers/chat_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
// 🛑 CORREGIDO: Usamos el paquete oficial
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:tu_flota/core/services/gemini_service.dart';

// Definición para los mensajes que se muestran en la UI
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

// Estado del Chat
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatState({required this.messages, this.isLoading = false, this.error});

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  final GeminiService _geminiService;

  ChatController(this._geminiService)
      : super(ChatState(messages: [])); // Estado inicial sin mensajes

  List<Content> _geminiChatHistory = []; 

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(text: text, isUser: true, timestamp: DateTime.now());
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    final userContent = Content.text(text);

    try {
      final responseText = await _geminiService.getResponse(text, _geminiChatHistory);

      // 🛑 CORREGIDO: La forma estándar de crear Content es con el constructor simple,
      // o la forma más estricta para asegurar el rol del modelo:
      final geminiResponse = Content(
        'model', // Rol: model
        [
          TextPart(responseText) // ✅ TextPart SÍ existe aquí
        ],
      );
      
      _geminiChatHistory.add(userContent);
      _geminiChatHistory.add(geminiResponse);

      final assistantMessage = ChatMessage(text: responseText, isUser: false, timestamp: DateTime.now());
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );
      
    } catch (e) {
      print('Error al enviar mensaje: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudo conectar con el asistente. Intenta más tarde.',
      );
    }
  }
}

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  return ChatController(geminiService);
});