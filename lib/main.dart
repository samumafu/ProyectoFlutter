import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/company/controllers/company_controller.dart';
import 'features/passenger/controllers/ticket_search_controller.dart';
import 'core/services/supabase_service.dart';
import 'controllers/auth_controller.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  await SupabaseService().init();
  
  await initializeDateFormatting('es', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => CompanyController()),
        ChangeNotifierProvider(create: (_) => TicketSearchController()),
      ],
      child: const TuFlotaApp(),
    );
  }
}
