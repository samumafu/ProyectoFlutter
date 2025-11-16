import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:tu_flota/core/constants/app_strings.dart';
import 'package:tu_flota/features/company/controllers/company_controller.dart';

class CompanyProfileScreen extends ConsumerWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companyControllerProvider);
    final company = state.company;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text(AppStrings.companyProfile, style: TextStyle(color: Colors.black87)),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/company/profile/edit'),
            icon: const Icon(Icons.edit, color: Colors.black87),
          )
        ],
      ),
      body: company == null
          ? const Center(child: Text(AppStrings.noCompanyData))
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 780;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 4,
                            shadowColor: Colors.black12,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: isWide
                                  ? Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 44,
                                          backgroundImage:
                                              company.logoUrl != null ? NetworkImage(company.logoUrl!) : null,
                                          child: company.logoUrl == null ? const Icon(Icons.business, size: 36) : null,
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(company.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 8),
                                              Text(company.email),
                                              Text(company.phone ?? '-'),
                                              Text(company.address ?? '-'),
                                              const SizedBox(height: 12),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: TextButton.icon(
                                                  onPressed: () async {
                                                    final urlCtrl = TextEditingController();
                                                    final fileNameCtrl = TextEditingController();
                                                    final res = await showDialog<bool>(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        title: const Text(AppStrings.updateLogo),
                                                        content: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            TextField(
                                                              controller: urlCtrl,
                                                              decoration: const InputDecoration(labelText: AppStrings.imageUrl),
                                                            ),
                                                            TextField(
                                                              controller: fileNameCtrl,
                                                              decoration: const InputDecoration(labelText: AppStrings.fileNameExample),
                                                            ),
                                                          ],
                                                        ),
                                                        actions: [
                                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancelLabel)),
                                                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(AppStrings.save)),
                                                        ],
                                                      ),
                                                    );
                                                    if (res == true) {
                                                      try {
                                                        final uri = Uri.parse(urlCtrl.text.trim());
                                                        final bd = await NetworkAssetBundle(uri).load(uri.path);
                                                        final bytes = bd.buffer.asUint8List();
                                                        final name = fileNameCtrl.text.trim().isEmpty
                                                            ? uri.pathSegments.isNotEmpty
                                                                ? uri.pathSegments.last
                                                                : 'logo.png'
                                                            : fileNameCtrl.text.trim();
                                                        await ref.read(companyControllerProvider.notifier).uploadLogo(bytes, name);
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(context)
                                                              .showSnackBar(const SnackBar(content: Text(AppStrings.success)));
                                                        }
                                                      } catch (e) {
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(context)
                                                              .showSnackBar(SnackBar(content: Text('${AppStrings.error}: $e')));
                                                        }
                                                      }
                                                    }
                                                  },
                                                  icon: const Icon(Icons.upload_file),
                                                  label: const Text(AppStrings.updateLogo),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 44,
                                              backgroundImage:
                                                  company.logoUrl != null ? NetworkImage(company.logoUrl!) : null,
                                              child: company.logoUrl == null ? const Icon(Icons.business, size: 36) : null,
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(company.name, style: Theme.of(context).textTheme.titleLarge),
                                                  Text(company.email),
                                                  Text(company.phone ?? '-'),
                                                  Text(company.address ?? '-'),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            onPressed: () async {
                                              final urlCtrl = TextEditingController();
                                              final fileNameCtrl = TextEditingController();
                                              final res = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text(AppStrings.updateLogo),
                                                  content: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      TextField(
                                                        controller: urlCtrl,
                                                        decoration: const InputDecoration(labelText: AppStrings.imageUrl),
                                                      ),
                                                      TextField(
                                                        controller: fileNameCtrl,
                                                        decoration: const InputDecoration(labelText: AppStrings.fileNameExample),
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancelLabel)),
                                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(AppStrings.save)),
                                                  ],
                                                ),
                                              );
                                              if (res == true) {
                                                try {
                                                  final uri = Uri.parse(urlCtrl.text.trim());
                                                  final bd = await NetworkAssetBundle(uri).load(uri.path);
                                                  final bytes = bd.buffer.asUint8List();
                                                  final name = fileNameCtrl.text.trim().isEmpty
                                                      ? uri.pathSegments.isNotEmpty
                                                          ? uri.pathSegments.last
                                                          : 'logo.png'
                                                      : fileNameCtrl.text.trim();
                                                  await ref.read(companyControllerProvider.notifier).uploadLogo(bytes, name);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(const SnackBar(content: Text(AppStrings.success)));
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(SnackBar(content: Text('${AppStrings.error}: $e')));
                                                  }
                                                }
                                              }
                                            },
                                            icon: const Icon(Icons.upload_file),
                                            label: const Text(AppStrings.updateLogo),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Card(
                            elevation: 3,
                            shadowColor: Colors.black12,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text('${AppStrings.nit}: ${company.nit ?? '-'}')),
                                      Expanded(child: Text('${AppStrings.active}: ${company.isActive ? AppStrings.yes : AppStrings.no }')),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text('${AppStrings.description}: ${company.description ?? '-'}'),
                                  const SizedBox(height: 20),
                                  const Text(AppStrings.companyRoutes),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: company.routes.isEmpty
                                        ? [const Chip(label: Text('-'))]
                                        : company.routes
                                            .map((r) => Chip(
                                                  label: Text(r),
                                                  backgroundColor: Colors.blueGrey.shade50,
                                                ))
                                            .toList(),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(AppStrings.companySettings),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('${company.settings ?? {}}'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}