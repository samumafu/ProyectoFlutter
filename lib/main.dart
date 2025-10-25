import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Supabase
  await SupabaseService().init();

  runApp(const TuFlotaApp());
}
