import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../app_config.dart';
import '../data/driver_repository.dart';
import 'driver_dashboard_screen.dart';

class DriverOnboardingScreen extends StatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  State<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _licenseExpiryController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _vehicleYearController = TextEditingController();

  final Set<String> _selectedTypes = {};
  final Map<String, File?> _files = {
    'licenseFront': null,
    'licenseBack': null,
    'insurance': null,
    'idDocument': null,
    'vehiclePhoto': null,
  };

  bool _agreed = false;
  bool _isSubmitting = false;
  bool _submitted = false;
  final _repository = DriverRepository();
  final _picker = ImagePicker();

  final _docLabels = const {
    'licenseFront': 'رخصة القيادة (الأمام)',
    'licenseBack': 'رخصة القيادة (الخلف)',
    'insurance': 'وثيقة التأمين',
    'idDocument': 'بطاقة الهوية / السجل التجاري',
    'vehiclePhoto': 'صورة السطحة',
  };

  Future<void> _pickImage(String key) async {
    final image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
    if (image != null) setState(() => _files[key] = File(image.path));
  }

  String? _imageToBase64(File? file) {
    if (file == null) return null;
    return 'data:image/jpeg;base64,${base64Encode(file.readAsBytesSync())}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر فئة واحدة على الأقل')));
      return;
    }
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب الموافقة على الشروط')));
      return;
    }
    if (_files.values.any((f) => f == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء رفع جميع الوثائق')));
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _repository.apply(
      fullName: _fullNameController.text.trim(),
      licenseNumber: _licenseNumberController.text.trim(),
      licenseExpiry: _licenseExpiryController.text.trim(),
      plateNumber: _plateNumberController.text.trim(),
      vehicleYear: int.tryParse(_vehicleYearController.text.trim()) ?? 0,
      vehicleTypes: _selectedTypes.toList(),
      documents: _files.map((k, v) => MapEntry(k, _imageToBase64(v))),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (_) => setState(() => _submitted = true),
      failure: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _licenseNumberController.dispose();
    _licenseExpiryController.dispose();
    _plateNumberController.dispose();
    _vehicleYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_submitted) {
      return Scaffold(
        appBar: AppBar(title: const Text('طلب الشراكة')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 80),
                const SizedBox(height: AppSpacing.lg),
                Text('تم إرسال طلبك بنجاح', style: AppTextStyles.headline(colors.textPrimary)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'جاري مراجعة الوثائق من قبل الإدارة، سيتم تفعيل حسابك قريباً',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'الانتقال إلى لوحة السائق',
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('طلب الشراكة للسائقين')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('المعلومات الشخصية والمركبة', style: AppTextStyles.title(colors.textPrimary)),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'الاسم الكامل',
                controller: _fullNameController,
                prefixIcon: Icons.person_outline,
                validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'رقم رخصة القيادة',
                controller: _licenseNumberController,
                prefixIcon: Icons.badge_outlined,
                validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'تاريخ صلاحية الرخصة (YYYY-MM-DD)',
                controller: _licenseExpiryController,
                prefixIcon: Icons.calendar_today_outlined,
                validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'رقم لوحة السطحة',
                controller: _plateNumberController,
                prefixIcon: Icons.local_shipping_outlined,
                validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'سنة الصنع',
                controller: _vehicleYearController,
                prefixIcon: Icons.date_range_outlined,
                keyboardType: TextInputType.number,
                validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('فئات السطحات المتاحة للقطر', style: AppTextStyles.title(colors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: AppConfig.vehicleCategories.entries.map((entry) {
                  final isSelected = _selectedTypes.contains(entry.key);
                  return GestureDetector(
                    onTap: () => setState(() => isSelected ? _selectedTypes.remove(entry.key) : _selectedTypes.add(entry.key)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : colors.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(entry.value, style: AppTextStyles.bodyMedium(isSelected ? Colors.white : colors.textPrimary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('رفع الوثائق', style: AppTextStyles.title(colors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              ..._docLabels.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _UploadCard(
                      label: entry.value,
                      file: _files[entry.key],
                      onTap: () => _pickImage(entry.key),
                    ),
                  )),
              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  Checkbox(
                    value: _agreed,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                  ),
                  Expanded(
                    child: Text(
                      'أوافق على الشروط ونظام الرصيد المسبق للعمولة',
                      style: AppTextStyles.bodyMedium(colors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              AppButton(
                label: _isSubmitting ? 'جاري الإرسال...' : 'إرسال طلب الشراكة',
                icon: Icons.send_rounded,
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  final String label;
  final File? file;
  final VoidCallback onTap;

  const _UploadCard({required this.label, required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.border),
        ),
        child: file == null
            ? Row(
                children: [
                  const Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(label, style: AppTextStyles.bodyMedium(colors.textPrimary))),
                  const Icon(Icons.add_rounded, color: AppColors.primary),
                ],
              )
            : Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.file(file!, width: 48, height: 48, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(label, style: AppTextStyles.bodyMedium(colors.textPrimary))),
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                ],
              ),
      ),
    );
  }
}
