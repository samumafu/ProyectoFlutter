import 'package:flutter/material.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/core/services/supabase_service.dart';

class DriverDashboardScreen extends StatelessWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.driverDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.signOut,
            onPressed: () async {
              await SupabaseService().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/auth/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(AppStrings.featureComingSoon),
      ),
    );
  }
}