import 'package:flutter/material.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';

class PassengerTripCard extends StatelessWidget {
  final CompanySchedule schedule;
  final VoidCallback onOpen;
  const PassengerTripCard({super.key, required this.schedule, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.directions_bus),
        title: Text('${schedule.origin} → ${schedule.destination}'),
        subtitle: Text('Departs: ${schedule.departureTime} • Price: ${schedule.price}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onOpen,
      ),
    );
  }
}