class Validators {
  // Validador requerido
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Este campo'} es requerido';
    }
    return null;
  }

  // Validador de email
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingrese un email válido';
    }
    
    return null;
  }

  // Validador de contraseña
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    
    return null;
  }

  // Validador de confirmación de contraseña
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirme la contraseña';
    }
    
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    
    return null;
  }

  // Validador de teléfono
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Opcional
    }
    
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Ingrese un teléfono válido (10 dígitos)';
    }
    
    return null;
  }

  // Validador de cédula
  static String? cedula(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La cédula es requerida';
    }
    
    final cedulaRegex = RegExp(r'^[0-9]{8,10}$');
    if (!cedulaRegex.hasMatch(value.trim())) {
      return 'Ingrese una cédula válida (8-10 dígitos)';
    }
    
    return null;
  }

  // Validador de NIT
  static String? nit(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El NIT es requerido';
    }
    
    final nitRegex = RegExp(r'^[0-9]{9,10}$');
    if (!nitRegex.hasMatch(value.trim())) {
      return 'Ingrese un NIT válido (9-10 dígitos)';
    }
    
    return null;
  }

  // Validador de placa de vehículo
  static String? placa(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La placa es requerida';
    }
    
    final placaRegex = RegExp(r'^[A-Z]{3}[0-9]{3}$');
    if (!placaRegex.hasMatch(value.trim().toUpperCase())) {
      return 'Ingrese una placa válida (ABC123)';
    }
    
    return null;
  }

  // Validador de número positivo
  static String? positiveNumber(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Este campo'} es requerido';
    }
    
    final number = double.tryParse(value.trim());
    if (number == null || number <= 0) {
      return '${fieldName ?? 'Este campo'} debe ser un número mayor a 0';
    }
    
    return null;
  }

  // Validador de número entero positivo
  static String? positiveInteger(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Este campo'} es requerido';
    }
    
    final number = int.tryParse(value.trim());
    if (number == null || number <= 0) {
      return '${fieldName ?? 'Este campo'} debe ser un número entero mayor a 0';
    }
    
    return null;
  }

  // Validador de longitud mínima
  static String? minLength(String? value, int minLength, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Este campo'} es requerido';
    }
    
    if (value.trim().length < minLength) {
      return '${fieldName ?? 'Este campo'} debe tener al menos $minLength caracteres';
    }
    
    return null;
  }

  // Validador de longitud máxima
  static String? maxLength(String? value, int maxLength, [String? fieldName]) {
    if (value != null && value.trim().length > maxLength) {
      return '${fieldName ?? 'Este campo'} no puede tener más de $maxLength caracteres';
    }
    
    return null;
  }

  // Validador de rango de longitud
  static String? lengthRange(String? value, int minLength, int maxLength, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Este campo'} es requerido';
    }
    
    final length = value.trim().length;
    if (length < minLength || length > maxLength) {
      return '${fieldName ?? 'Este campo'} debe tener entre $minLength y $maxLength caracteres';
    }
    
    return null;
  }

  // Validador de fecha
  static String? date(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'La fecha'} es requerida';
    }
    
    try {
      DateTime.parse(value.trim());
      return null;
    } catch (e) {
      return 'Ingrese una fecha válida';
    }
  }

  // Validador de fecha futura
  static String? futureDate(String? value, [String? fieldName]) {
    final dateError = date(value, fieldName);
    if (dateError != null) return dateError;
    
    final inputDate = DateTime.parse(value!.trim());
    final now = DateTime.now();
    
    if (inputDate.isBefore(now)) {
      return '${fieldName ?? 'La fecha'} debe ser futura';
    }
    
    return null;
  }

  // Validador de URL
  static String? url(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return null; // Opcional
    }
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'
    );
    
    if (!urlRegex.hasMatch(value.trim())) {
      return 'Ingrese una URL válida';
    }
    
    return null;
  }

  // Validador combinado
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}