import 'package:flutter/material.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'dart:convert';

class CompanyTripCard extends StatelessWidget {
  final CompanySchedule schedule;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewReservations;
  final VoidCallback? onOpenChat;

  const CompanyTripCard({
    super.key,
    required this.schedule,
    this.onEdit,
    this.onDelete,
    this.onViewReservations,
    this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(schedule.isActive ? Icons.directions_bus : Icons.remove_circle_outline,
                    color: schedule.isActive ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${schedule.origin} → ${schedule.destination}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('${schedule.price.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 6),
            Text('${AppStrings.departure}: ${schedule.departureTime}'),
            Text('${AppStrings.arrival}: ${schedule.arrivalTime}'),
            const SizedBox(height: 6),
            Text('${AppStrings.seats}: ${schedule.availableSeats}/${schedule.totalSeats}'),
            if (schedule.vehicleType != null) Text('${AppStrings.vehicle}: ${schedule.vehicleType}'),
            if (schedule.additionalInfo != null)
              Text('${AppStrings.info}: ${jsonEncode(schedule.additionalInfo)}'),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: onViewReservations,
                  icon: const Icon(Icons.group),
                  label: const Text(AppStrings.reservations),
                ),
                TextButton.icon(
                  onPressed: onOpenChat,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text(AppStrings.chat),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text(AppStrings.edit),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text(AppStrings.delete),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}