import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa la localización de fechas
  await initializeDateFormatting('es_ES', null);

  // Inicializa Supabase
  await SupabaseService().init();

  runApp(const TuFlotaApp());
}
