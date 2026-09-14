import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_common_widgets.dart';
import '../../../models/workshop_model.dart';
import '../data/workshop_repository.dart';

class WorkshopsScreen extends StatefulWidget {
  const WorkshopsScreen({super.key});

  @override
  State<WorkshopsScreen> createState() => _WorkshopsScreenState();
}

class _WorkshopsScreenState extends State<WorkshopsScreen> {
  final _repository = WorkshopRepository();
  List<WorkshopModel> _workshops = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _repository.fetchWorkshops();
    if (!mounted) return;

    result.when(
      success: (data) => setState(() {
        _workshops = data;
        _isLoading = false;
      }),
      failure: (f) => setState(() {
        _error = f.message;
        _isLoading = false;
      }),
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _directions(WorkshopModel w) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${w.lat},${w.lng}');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ورشات التصليح'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: _isLoading
          ? const AppLoadingView()
          : _error != null
              ? AppEmptyState(icon: Icons.error_outline_rounded, title: 'تعذر تحميل الورشات', subtitle: _error)
              : _workshops.isEmpty
                  ? const AppEmptyState(icon: Icons.build_circle_outlined, title: 'لا توجد ورشات متاحة حالياً')
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: _workshops.length,
                      itemBuilder: (context, index) {
                        final w = _workshops[index];
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.build_rounded, color: AppColors.accent),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(w.name, style: AppTextStyles.title(colors.textPrimary)),
                                        Text(w.specialty, style: AppTextStyles.bodySmall(colors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                                      Text(w.rating.toStringAsFixed(1), style: AppTextStyles.bodyMedium(colors.textPrimary)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _call(w.phone),
                                      icon: const Icon(Icons.phone_rounded, size: 18),
                                      label: const Text('اتصال'),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _directions(w),
                                      icon: const Icon(Icons.directions_rounded, size: 18),
                                      label: const Text('توجيه'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
