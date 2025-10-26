import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/ticket_model.dart';

class ChatScreen extends StatefulWidget {
  final Ticket ticket;

  const ChatScreen({
    Key? key,
    required this.ticket,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
  }

  void _loadInitialMessages() {
    // Mensajes de ejemplo
    _messages.addAll([
      ChatMessage(
        text: '¡Hola! Soy ${widget.ticket.companyName}, conductor de su viaje ${widget.ticket.origin} - ${widget.ticket.destination}',
        isFromDriver: true,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ChatMessage(
        text: 'El viaje está confirmado para las ${DateFormat('HH:mm').format(widget.ticket.departureTime)}',
        isFromDriver: true,
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 1)),
      ),
      ChatMessage(
        text: 'Perfecto, gracias por la información',
        isFromDriver: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      ),
    ]);
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: _messageController.text.trim(),
        isFromDriver: false,
        timestamp: DateTime.now(),
      ));
    });

    _messageController.clear();
    _scrollToBottom();

    // Simular respuesta del conductor después de un delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: _getDriverResponse(),
            isFromDriver: true,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    });
  }

  String _getDriverResponse() {
    final responses = [
      'Perfecto, nos vemos en el punto de encuentro',
      'Entendido, cualquier cosa me avisa',
      'Gracias por escribir, buen viaje',
      'Estaré atento a cualquier novedad',
      'De acuerdo, nos vemos pronto',
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ticket.companyName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.ticket.origin} → ${widget.ticket.destination}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showTripInfo(),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          // Información del viaje
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_bus, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Viaje: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.ticket.departureTime)}',
                    style: TextStyle(
                      color: Colors.indigo.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Confirmado',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de mensajes
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          
          // Campo de entrada de mensaje
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isFromDriver 
            ? MainAxisAlignment.start 
            : MainAxisAlignment.end,
        children: [
          if (message.isFromDriver) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.indigo,
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isFromDriver 
                    ? Colors.grey.shade200 
                    : Colors.indigo,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: message.isFromDriver 
                      ? const Radius.circular(4) 
                      : const Radius.circular(18),
                  bottomRight: message.isFromDriver 
                      ? const Radius.circular(18) 
                      : const Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isFromDriver ? Colors.black87 : Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      color: message.isFromDriver 
                          ? Colors.grey.shade600 
                          : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!message.isFromDriver) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade400,
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  void _showTripInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información del Viaje'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Ruta:', '${widget.ticket.origin} → ${widget.ticket.destination}'),
            _buildInfoRow('Fecha:', DateFormat('dd/MM/yyyy').format(widget.ticket.departureTime)),
            _buildInfoRow('Hora salida:', DateFormat('HH:mm').format(widget.ticket.departureTime)),
            _buildInfoRow('Hora llegada:', DateFormat('HH:mm').format(widget.ticket.arrivalTime)),
            _buildInfoRow('Empresa:', widget.ticket.companyName),
            _buildInfoRow('Tipo de bus:', widget.ticket.busType),
            _buildInfoRow('Precio:', '\$${widget.ticket.price.toStringAsFixed(0)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isFromDriver;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isFromDriver,
    required this.timestamp,
  });
}