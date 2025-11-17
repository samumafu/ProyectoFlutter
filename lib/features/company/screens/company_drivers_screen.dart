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
      final notifier = ref.read(companyControllerProvider.notifier);
      final current = ref.read(companyControllerProvider);
      if (current.user == null || current.company == null) {
        await notifier.loadAuthAndCompany();
      }
      await notifier.loadDrivers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyControllerProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text(AppStrings.companyDrivers, style: TextStyle(color: Colors.black87)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/company/driver/add'),
        child: const Icon(Icons.person_add),
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isGrid = constraints.maxWidth >= 900;
                  final sidePad = isGrid ? (constraints.maxWidth - 900) / 2 : 0;
                  final contentPad = EdgeInsets.symmetric(
                    horizontal: (sidePad.clamp(0, 80) as double),
                    vertical: 16,
                  );
                  final gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 3.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  );
                  return Padding(
                    padding: contentPad,
                    child: isGrid
                        ? GridView.builder(
                            itemCount: state.drivers.length,
                            gridDelegate: gridDelegate,
                            itemBuilder: (context, index) {
                              final d = state.drivers[index];
                              return Card(
                                elevation: 3,
                                shadowColor: Colors.black12,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.blueGrey.shade100,
                                        child: Text(d.name.isNotEmpty ? d.name[0] : '?'),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                                            const SizedBox(height: 4),
                                            if (d.phone != null) Text('${AppStrings.phone}: ${d.phone}', maxLines: 1, overflow: TextOverflow.ellipsis),
                                            if (d.autoModel != null) Text('${AppStrings.vehicleModel}: ${d.autoModel} ${d.autoColor ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
                                            if (d.autoPlate != null) Text('${AppStrings.plate}: ${d.autoPlate}', maxLines: 1, overflow: TextOverflow.ellipsis),
                                            if (d.rating != null) Text('${AppStrings.rating}: ${d.rating}', maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                      Wrap(
                                        spacing: 6,
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
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            itemCount: state.drivers.length,
                            itemBuilder: (context, index) {
                              final d = state.drivers[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                elevation: 2,
                                shadowColor: Colors.black12,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blueGrey.shade100,
                                    child: Text(d.name.isNotEmpty ? d.name[0] : '?'),
                                  ),
                                  title: Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (d.phone != null) Text('${AppStrings.phone}: ${d.phone}', maxLines: 1, overflow: TextOverflow.ellipsis),
                                      if (d.autoModel != null) Text('${AppStrings.vehicleModel}: ${d.autoModel} ${d.autoColor ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
                                      if (d.autoPlate != null) Text('${AppStrings.plate}: ${d.autoPlate}', maxLines: 1, overflow: TextOverflow.ellipsis),
                                      if (d.rating != null) Text('${AppStrings.rating}: ${d.rating}', maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                  trailing: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
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
                },
              ),
      ),
    );
  }
}