import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/features/passenger/controllers/passenger_controller.dart';
import 'package:tu_flota/features/company/models/company_schedule_model.dart';
import 'package:tu_flota/core/services/supabase_service.dart';

class PassengerTripDetailScreen extends ConsumerStatefulWidget {
  final Object? schedule;
  const PassengerTripDetailScreen({super.key, this.schedule});

  @override
  ConsumerState<PassengerTripDetailScreen> createState() => _PassengerTripDetailScreenState();
}

class _PassengerTripDetailScreenState extends ConsumerState<PassengerTripDetailScreen> {
  late final CompanySchedule _s;
  final _seatsCtrl = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _s = widget.schedule as CompanySchedule;
  }

  @override
  void dispose() {
    _seatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _reserve() async {
    final seats = int.tryParse(_seatsCtrl.text.trim()) ?? 1;
    try {
      await ref.read(passengerControllerProvider.notifier).reserveSeats(schedule: _s, seats: seats);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.success)));
      Navigator.pushNamedAndRemoveUntil(context, '/passenger/dashboard', (route) => false);
    } catch (_) {
      if (!mounted) return;
      final err = ref.read(passengerControllerProvider).error ?? AppStrings.actionFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      final client = ref.read(supabaseProvider);
      if (client.auth.currentUser == null) {
        Navigator.pushNamed(context, '/auth/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tripDetail)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 420;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_s.origin} → ${_s.destination}', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Departure: ${_s.departureTime}'),
                  Text('Arrival: ${_s.arrivalTime}'),
                  const SizedBox(height: 8),
                  Text('Price: ${_s.price}'),
                  Text('Available seats: ${_s.availableSeats}'),
                  const SizedBox(height: 16),
                  if (isNarrow)
                    Column(
                      children: [
                        TextField(
                          controller: _seatsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: AppStrings.seatsToReserve),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(onPressed: _reserve, child: const Text(AppStrings.reserve)),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _seatsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: AppStrings.seatsToReserve),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: _reserve, child: const Text(AppStrings.reserve)),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}