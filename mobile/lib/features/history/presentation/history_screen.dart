import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_common_widgets.dart';
import '../../../models/tow_request_model.dart';
import '../data/history_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _repository = HistoryRepository();
  List<TowRequestModel> _requests = [];
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

    final result = await _repository.fetchHistory();
    if (!mounted) return;

    result.when(
      success: (data) => setState(() {
        _requests = data;
        _isLoading = false;
      }),
      failure: (f) => setState(() {
        _error = f.message;
        _isLoading = false;
      }),
    );
  }

  String _statusLabel(String status) {
    const map = {
      'pending': 'قيد الانتظار',
      'accepted': 'مقبول',
      'in_progress': 'جارية',
      'completed': 'مكتملة',
      'cancelled': 'ملغية',
    };
    return map[status] ?? status;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('سجل الطلبات')),
      body: _isLoading
          ? const AppLoadingView()
          : _error != null
              ? AppEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'تعذر تحميل السجل',
                  subtitle: _error,
                )
              : _requests.isEmpty
                  ? const AppEmptyState(icon: Icons.history_rounded, title: 'لا توجد طلبات سابقة')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final r = _requests[index];
                          return AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}',
                                      style: AppTextStyles.bodySmall(colors.textSecondary),
                                    ),
                                    StatusBadge.fromStatus(r.status, translate: _statusLabel),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    Text(
                                      AppConfig.vehicleCategories[r.vehicleCategory] ?? r.vehicleCategory,
                                      style: AppTextStyles.title(colors.textPrimary),
                                    ),
                                    const Spacer(),
                                    Text('${r.price.round()} ${AppConfig.currency}', style: AppTextStyles.title(AppColors.primary)),
                                  ],
                                ),
                              ],
                            ),
                          ).animate().fadeIn();
                        },
                      ),
                    ),
    );
  }
}
