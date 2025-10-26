import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking.dart';

class BookingService {
  static const String _bookingsKey = 'user_bookings';

  /// Guarda una nueva reserva en el historial
  static Future<void> saveBooking(Booking booking) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookings = await getBookings();
      
      bookings.add(booking);
      
      final bookingsJson = bookings.map((b) => b.toJson()).toList();
      await prefs.setString(_bookingsKey, jsonEncode(bookingsJson));
    } catch (e) {
      print('Error saving booking: $e');
    }
  }

  /// Obtiene todas las reservas del historial
  static Future<List<Booking>> getBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingsString = prefs.getString(_bookingsKey);
      
      if (bookingsString == null) {
        return [];
      }
      
      final bookingsJson = jsonDecode(bookingsString) as List;
      return bookingsJson.map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      print('Error loading bookings: $e');
      return [];
    }
  }

  /// Obtiene las reservas ordenadas por fecha (más recientes primero)
  static Future<List<Booking>> getBookingsSortedByDate() async {
    final bookings = await getBookings();
    bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
    return bookings;
  }

  /// Obtiene una reserva específica por ID
  static Future<Booking?> getBookingById(String id) async {
    final bookings = await getBookings();
    try {
      return bookings.firstWhere((booking) => booking.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Actualiza el estado de una reserva
  static Future<void> updateBookingStatus(String bookingId, BookingStatus newStatus) async {
    try {
      final bookings = await getBookings();
      final bookingIndex = bookings.indexWhere((b) => b.id == bookingId);
      
      if (bookingIndex != -1) {
        final updatedBooking = Booking(
          id: bookings[bookingIndex].id,
          origin: bookings[bookingIndex].origin,
          destination: bookings[bookingIndex].destination,
          departureDate: bookings[bookingIndex].departureDate,
          departureTime: bookings[bookingIndex].departureTime,
          selectedSeats: bookings[bookingIndex].selectedSeats,
          totalPrice: bookings[bookingIndex].totalPrice,
          pickupPointName: bookings[bookingIndex].pickupPointName,
          pickupPointDescription: bookings[bookingIndex].pickupPointDescription,
          pickupPointCoordinates: bookings[bookingIndex].pickupPointCoordinates,
          bookingDate: bookings[bookingIndex].bookingDate,
          status: newStatus,
        );
        
        bookings[bookingIndex] = updatedBooking;
        
        final prefs = await SharedPreferences.getInstance();
        final bookingsJson = bookings.map((b) => b.toJson()).toList();
        await prefs.setString(_bookingsKey, jsonEncode(bookingsJson));
      }
    } catch (e) {
      print('Error updating booking status: $e');
    }
  }

  /// Elimina una reserva del historial
  static Future<void> deleteBooking(String bookingId) async {
    try {
      final bookings = await getBookings();
      bookings.removeWhere((booking) => booking.id == bookingId);
      
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = bookings.map((b) => b.toJson()).toList();
      await prefs.setString(_bookingsKey, jsonEncode(bookingsJson));
    } catch (e) {
      print('Error deleting booking: $e');
    }
  }

  /// Limpia todo el historial de reservas
  static Future<void> clearAllBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bookingsKey);
    } catch (e) {
      print('Error clearing bookings: $e');
    }
  }

  /// Genera un ID único para una nueva reserva
  static String generateBookingId() {
    return 'booking_${DateTime.now().millisecondsSinceEpoch}';
  }
}