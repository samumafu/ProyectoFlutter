import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';
import 'package:tu_flota/features/company/models/chat_message_model.dart';

typedef OnMessage = void Function(ChatMessage msg);

class ChatService {
  final SupabaseClient client;
  ChatService(this.client);

  Future<List<ChatMessage>> listMessages(String tripId) async {
    final data = await client
        .from('chat_messages')
        .select()
        .eq('trip_id', tripId)
        .order('id');
    return (data as List<dynamic>)
        .map((e) => ChatMessage.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> sendMessage({
    required String tripId,
    required String senderId,
    required String message,
  }) async {
    final inserted = await client
        .from('chat_messages')
        .insert({
          'trip_id': tripId,
          'sender_id': senderId,
          'message': message,
        })
        .select()
        .maybeSingle();
    return ChatMessage.fromMap(inserted!);
  }

  RealtimeChannel subscribeTripMessages(String tripId, OnMessage onMessage) {
    final channel = client.channel('public:chat_messages').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_messages',
      callback: (payload) {
        final newRow = payload.newRecord;
        if (newRow != null) {
          final rowTripId = newRow['trip_id']?.toString();
          if (rowTripId == tripId) {
            onMessage(ChatMessage.fromMap(newRow));
          }
        }
      },
    );
    channel.subscribe();
    return channel;
  }
}