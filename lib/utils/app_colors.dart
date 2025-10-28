import 'package:flutter/material.dart';

class AppColors {
  // Colores primarios
  static const Color primary = Color(0xFF3F51B5); // Indigo
  static const Color primaryLight = Color(0xFF7986CB);
  static const Color primaryDark = Color(0xFF303F9F);

  // Colores secundarios
  static const Color secondary = Color(0xFF03DAC6);
  static const Color secondaryLight = Color(0xFF66FFF9);
  static const Color secondaryDark = Color(0xFF00A896);

  // Colores de estado
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Colores de fondo
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F3F3);

  // Colores de texto
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Colores específicos de la aplicación
  static const Color vehicleCard = Color(0xFFE3F2FD);
  static const Color documentExpired = Color(0xFFFFEBEE);
  static const Color documentExpiring = Color(0xFFFFF3E0);
  static const Color documentValid = Color(0xFFE8F5E8);

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF66BB6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warning, Color(0xFFFFB74D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, Color(0xFFEF5350)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Métodos de utilidad
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'activo':
      case 'disponible':
      case 'completado':
        return success;
      case 'inactivo':
      case 'mantenimiento':
      case 'pendiente':
        return warning;
      case 'cancelado':
      case 'vencido':
      case 'bloqueado':
        return error;
      default:
        return textSecondary;
    }
  }

  static Color getVehicleStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disponible':
        return success;
      case 'en_ruta':
        return info;
      case 'mantenimiento':
        return warning;
      case 'fuera_de_servicio':
        return error;
      default:
        return textSecondary;
    }
  }

  static Color getDocumentStatusColor(DateTime? expirationDate) {
    if (expirationDate == null) return textSecondary;
    
    final now = DateTime.now();
    final daysUntilExpiration = expirationDate.difference(now).inDays;
    
    if (daysUntilExpiration < 0) {
      return error; // Vencido
    } else if (daysUntilExpiration <= 30) {
      return warning; // Por vencer
    } else {
      return success; // Vigente
    }
  }
}