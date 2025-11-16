import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_flota/features/company/controllers/company_controller.dart';
import 'package:tu_flota/features/company/models/company_model.dart';
import 'package:tu_flota/core/constants/app_strings.dart';

class CompanyDriversScreen extends ConsumerStatefulWidget {
  const CompanyDriversScreen({super.key});

  @override
  ConsumerState<CompanyDriversScreen> createState() => _CompanyDriversScreenState();
}

class _CompanyDriversScreenState extends ConsumerState<CompanyDriversScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(companyControllerProvider.notifier).loadAuthAndCompany();
      await ref.read(companyControllerProvider.notifier).loadDrivers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.companyDrivers),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/company/driver/add'),
        child: const Icon(Icons.person_add),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: state.drivers.length,
              itemBuilder: (context, index) {
                final d = state.drivers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(d.name.isNotEmpty ? d.name[0] : '?')),
                    title: Text(d.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (d.phone != null) Text('${AppStrings.phone}: ${d.phone}'),
                        if (d.autoModel != null) Text('${AppStrings.vehicleModel}: ${d.autoModel} ${d.autoColor ?? ''}'),
                        if (d.autoPlate != null) Text('${AppStrings.plate}: ${d.autoPlate}'),
                        if (d.rating != null) Text('${AppStrings.rating}: ${d.rating}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: d.available,
                          onChanged: (value) => ref
                              .read(companyControllerProvider.notifier)
                              .toggleDriverAvailability(d.id, value),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await ref
                                .read(companyControllerProvider.notifier)
                                .deleteDriver(d.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(content: Text(AppStrings.driverDeleted)));
                            }
                          },
                        )
                      ],
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/company/driver/edit',
                        arguments: d,
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}