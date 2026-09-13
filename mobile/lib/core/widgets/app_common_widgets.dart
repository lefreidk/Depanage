import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// بطاقة موحّدة بحواف وحشو ثابتين — تُستخدم بدل Card مباشرة
/// حتى لا تتكرر قيم الحشو/الانحناء في كل شاشة.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(child: Padding(padding: padding, child: child));
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: card,
    );
  }
}

/// شارة حالة ملونة (قيد الانتظار / مقبول / مكتمل / ملغى...)
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  factory StatusBadge.fromStatus(String status, {required String Function(String) translate}) {
    final map = <String, Color>{
      'pending': AppColors.statusPending,
      'accepted': AppColors.statusAccepted,
      'in_progress': AppColors.statusInProgress,
      'completed': AppColors.statusCompleted,
      'cancelled': AppColors.statusCancelled,
      'rejected': AppColors.statusCancelled,
      'approved': AppColors.statusCompleted,
    };
    return StatusBadge(label: translate(status), color: map[status] ?? AppColors.statusPending);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label, style: AppTextStyles.caption(color)),
    );
  }
}

/// حالة فارغة موحّدة (لا يوجد سجل، لا توجد ورشات...)
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(color: colors.surfaceAlt, shape: BoxShape.circle),
              child: Icon(icon, size: 42, color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTextStyles.title(colors.textPrimary), textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle!, style: AppTextStyles.bodyMedium(colors.textSecondary), textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
          ],
        ),
      ),
    );
  }
}

/// مؤشر تحميل بملء الشاشة مع نص اختياري
class AppLoadingView extends StatelessWidget {
  final String? message;
  const AppLoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(message!, style: AppTextStyles.bodyMedium(colors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

/// شريط علوي مقوّس بخلفية متدرجة — يُستخدم في شاشات الملخص/الترحيب
class GradientHeader extends StatelessWidget {
  final Widget child;
  final double height;
  final Gradient gradient;

  const GradientHeader({
    super.key,
    required this.child,
    this.height = 180,
    this.gradient = AppColors.primaryGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
      ),
      child: child,
    );
  }
}
