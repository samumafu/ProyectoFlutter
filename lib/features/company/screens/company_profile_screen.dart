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
      appBar: AppBar(
        title: const Text(AppStrings.companyProfile),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/company/profile/edit'),
            icon: const Icon(Icons.edit),
          )
        ],
      ),
      body: company == null
          ? const Center(child: Text(AppStrings.noCompanyData))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundImage:
                            company.logoUrl != null ? NetworkImage(company.logoUrl!) : null,
                        child: company.logoUrl == null
                            ? const Icon(Icons.business, size: 32)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(company.name,
                                style: Theme.of(context).textTheme.titleLarge),
                            Text(company.email),
                            Text(company.phone ?? '-'),
                            Text(company.address ?? '-'),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
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
                          final name = fileNameCtrl.text.trim().isEmpty ? uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'logo.png' : fileNameCtrl.text.trim();
                          await ref.read(companyControllerProvider.notifier).uploadLogo(bytes, name);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.success)));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppStrings.error}: $e')));
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text(AppStrings.updateLogo),
                  ),
                  const SizedBox(height: 16),
                  Text('${AppStrings.nit}: ${company.nit ?? '-'}'),
                  const SizedBox(height: 8),
                  Text('${AppStrings.description}: ${company.description ?? '-'}'),
                  const SizedBox(height: 8),
                  Text('${AppStrings.active}: ${company.isActive ? AppStrings.yes : AppStrings.no }'),
                  const SizedBox(height: 16),
                  const Text(AppStrings.companyRoutes),
                  Wrap(
                    spacing: 8,
                    children: company.routes.isEmpty
                        ? [const Chip(label: Text('-'))]
                        : company.routes.map((r) => Chip(label: Text(r))).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(AppStrings.companySettings),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${company.settings ?? {}}'),
                  ),
                ],
              ),
            ),
    );
  }
}