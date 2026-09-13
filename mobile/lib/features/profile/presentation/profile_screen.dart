import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: context.read<AuthProvider>().user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final result = await ApiClient.instance.patch<void>(
      '/api/users/me',
      body: {'name': _nameController.text.trim()},
      parser: (_) {},
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الاسم'))),
      failure: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.person_rounded, size: 54, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(label: 'الاسم الكامل', controller: _nameController, prefixIcon: Icons.person_outline),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'رقم الهاتف',
              initialValue: auth.user?.phone ?? '',
              readOnly: true,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: _isSaving ? 'جاري الحفظ...' : 'حفظ التغييرات',
              icon: Icons.save_rounded,
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
