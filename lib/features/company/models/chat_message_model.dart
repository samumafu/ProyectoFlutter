// ➕ lib/features/company/models/chat_message_model.dart
class ChatMessage {
  final String id;
  final String tripId;
  final String senderId;
  final String message;
  final DateTime? createdAt; 

  const ChatMessage({
    required this.id,
    required this.tripId,
    required this.senderId,
    required this.message,
    this.createdAt, 
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      tripId: map['trip_id'] as String,
      senderId: map['sender_id'] as String,
      message: map['message'] as String,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String) 
          : null,
    );
  }
}