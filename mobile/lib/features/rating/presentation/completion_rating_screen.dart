import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../home/presentation/home_screen.dart';
import '../../request/providers/request_provider.dart';
import '../data/rating_repository.dart';

class CompletionRatingScreen extends StatefulWidget {
  const CompletionRatingScreen({super.key});

  @override
  State<CompletionRatingScreen> createState() => _CompletionRatingScreenState();
}

class _CompletionRatingScreenState extends State<CompletionRatingScreen> {
  int _rating = 0;
  final Set<String> _tags = {};
  bool _isSubmitting = false;
  final _repository = RatingRepository();

  final _quickTags = const ['سرعة الاستجابة', 'أمان في القطر', 'تعامل راقي', 'التزام بالسعر'];

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار التقييم')));
      return;
    }

    setState(() => _isSubmitting = true);

    final tripId = context.read<RequestProvider>().completedTripId;
    if (tripId != null) {
      await _repository.rateTrip(tripId, _rating, _tags.toList());
    }

    if (!mounted) return;

    context.read<RequestProvider>().reset();
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final request = context.watch<RequestProvider>().currentRequest;

    return Scaffold(
      appBar: AppBar(title: const Text('إنهاء الرحلة'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 56),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: AppSpacing.lg),
            Text('تمت الرحلة بنجاح', style: AppTextStyles.headline(colors.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text('شكراً لاستخدامك ديباناج', style: AppTextStyles.bodyMedium(colors.textSecondary)),
            const SizedBox(height: AppSpacing.xl),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(color: colors.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: Row(
                children: [
                  const Icon(Icons.payments_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('المبلغ المدفوع نقداً', style: AppTextStyles.bodySmall(colors.textSecondary)),
                        Text(
                          request != null ? '${request.price.round()} ${AppConfig.currency}' : '—',
                          style: AppTextStyles.numericLarge(colors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('كيف كانت تجربتك؟', style: AppTextStyles.title(colors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = star),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      star <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppColors.warning,
                      size: 42,
                    ),
                  ),
                );
              }),
            ).animate().scale(delay: 150.ms),
            const SizedBox(height: AppSpacing.lg),

            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _quickTags.map((tag) {
                final isSelected = _tags.contains(tag);
                return GestureDetector(
                  onTap: () => setState(() => isSelected ? _tags.remove(tag) : _tags.add(tag)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(tag, style: AppTextStyles.bodyMedium(isSelected ? Colors.white : colors.textPrimary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xxl),

            AppButton(
              label: _isSubmitting ? 'جاري الإرسال...' : 'إرسال التقييم والعودة للرئيسية',
              icon: Icons.send_rounded,
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
