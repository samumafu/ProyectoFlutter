import 'package:flutter/material.dart';
import 'package:tu_flota/core/constants/app_strings.dart';

class DriverDashboardScreen extends StatelessWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.driverDashboard)),
      body: const Center(
        child: Text(AppStrings.featureComingSoon),
      ),
    );
  }
}