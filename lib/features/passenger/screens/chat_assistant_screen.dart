// lib/features/passenger/screens/chat_assistant_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/features/passenger/controllers/chat_controller.dart';

// Definiciones de estilo (usa los mismos colores para la consistencia)
const Color _despegarPrimaryBlue = Color(0xFF0073E6);
const Color _despegarLightBlue = Color(0xFFE6F3FF);
const Color _despegarDarkText = Color(0xFF333333);
const Color _despegarGreyText = Color(0xFF666666);


class ChatAssistantScreen extends ConsumerWidget {
  const ChatAssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatControllerProvider);
    final chatController = ref.read(chatControllerProvider.notifier);
    final TextEditingController messageController = TextEditingController();

    // Función para manejar el envío
    void sendMessage() {
      if (messageController.text.isNotEmpty) {
        chatController.sendMessage(messageController.text);
        messageController.clear();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente Virtual IA', 
          style: TextStyle(color: _despegarDarkText, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: _despegarPrimaryBlue),
      ),
      body: Column(
        children: [
          // 1. Área de Mensajes
          Expanded(
            child: ListView.builder(
              reverse: true, // Para que el scroll esté siempre abajo
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                // Se invierte el índice porque estamos usando reverse: true
                final message = chatState.messages[chatState.messages.length - 1 - index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // 2. Indicador de Carga/Error
          if (chatState.isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: _despegarPrimaryBlue),
            ),
          if (chatState.error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(chatState.error!, style: const TextStyle(color: Colors.red)),
            ),

          // 3. Campo de Entrada
          _buildInputField(messageController, sendMessage, chatState.isLoading),
        ],
      ),
    );
  }

  // --- Widgets de Ayuda ---

  Widget _buildMessageBubble(ChatMessage message) {
    // Determina si es un mensaje del usuario (derecha) o del asistente (izquierda)
    final isUser = message.isUser;
    
    // Colores y alineación
    final color = isUser ? _despegarPrimaryBlue : _despegarLightBlue;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final textColor = isUser ? Colors.white : _despegarDarkText;
    final icon = isUser ? Icons.person : Icons.support_agent;

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Ajusta el ancho al contenido
        crossAxisAlignment: CrossAxisAlignment.start,
        // Alineación de los elementos dentro de la fila
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start, 
        children: [
          // Icono del Asistente (solo si no es usuario)
          if (!isUser) 
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8.0),
              child: CircleAvatar(
                backgroundColor: _despegarPrimaryBlue,
                radius: 12,
                child: Icon(icon, size: 14, color: Colors.white),
              ),
            ),
          
          // Burbuja de Mensaje
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 16 : 4),
                  topRight: Radius.circular(isUser ? 4 : 16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(color: textColor, fontSize: 15),
              ),
            ),
          ),
          
          // Icono del Usuario (solo si es usuario)
          if (isUser) 
             Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0),
              child: CircleAvatar(
                backgroundColor: _despegarGreyText,
                radius: 12,
                child: Icon(icon, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, VoidCallback onSend, bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1.0)),
      ),
      child: SafeArea( // Asegura que no se superponga con la barra de navegación inferior
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null, // Múltiples líneas
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => isLoading ? null : onSend(),
                decoration: InputDecoration(
                  hintText: 'Pregúntale al asistente sobre tu viaje...',
                  hintStyle: const TextStyle(color: _despegarGreyText),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            IconButton(
              icon: isLoading 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: _despegarPrimaryBlue),
                    )
                  : const Icon(Icons.send),
              color: _despegarPrimaryBlue,
              onPressed: isLoading ? null : onSend,
            ),
          ],
        ),
      ),
    );
  }
}