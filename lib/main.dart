import 'package:flutter/material.dart';
import 'package:tu_flota/core/routing/app_router.dart';
import 'package:tu_flota/core/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  runApp(const AppRouter());
}
