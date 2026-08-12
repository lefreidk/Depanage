import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../providers/auth_provider.dart';
import '../theme.dart';
import '../config.dart';

class DriverOnboardingScreen extends StatefulWidget {
  @override
  _DriverOnboardingScreenState createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  // حقول المعلومات الشخصية
  final _fullNameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _licenseExpiryController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _vehicleYearController = TextEditingController();

  // فئات السطحات المحددة
  final Set<String> _selectedVehicleTypes = {};

  // صور الوثائق
  File? _licenseFront;
  File? _licenseBack;
  File? _insurance;
  File? _idDocument;
  File? _vehiclePhoto;

  bool _agreedToTerms = false;
  bool _isSubmitting = false;
  bool _submittedSuccessfully = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _fullNameController.dispose();
    _licenseNumberController.dispose();
    _licenseExpiryController.dispose();
    _plateNumberController.dispose();
    _vehicleYearController.dispose();
    super.dispose();
  }

  // التقاط صورة من الكاميرا أو المعرض
  Future<File?> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  // عرض خيارات التقاط الصورة
  Future<File?> _showImagePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppTheme.primary),
                title: Text('التقاط بالكاميرا'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppTheme.primary),
                title: Text('اختيار من المعرض'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source != null) {
      return await _pickImage(source);
    }
    return null;
  }

  // تحويل الصورة إلى Base64
  String? _imageToBase64(File? image) {
    if (image == null) return null;
    final bytes = image.readAsBytesSync();
    return base64Encode(bytes);
  }

  // إرسال طلب الشراكة
  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء اختيار فئة واحدة على الأقل')),
      );
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء الموافقة على الشروط والأحكام')),
      );
      return;
    }
    if (_licenseFront == null || _licenseBack == null || _insurance == null || _idDocument == null || _vehiclePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء رفع جميع الوثائق المطلوبة')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.user?.id ?? '1';

      // تجهيز بيانات الطلب مع الصور
      final body = {
        'userId': userId,
        'fullName': _fullNameController.text.trim(),
        'licenseNumber': _licenseNumberController.text.trim(),
        'licenseExpiry': _licenseExpiryController.text.trim(),
        'plateNumber': _plateNumberController.text.trim(),
        'vehicleYear': int.tryParse(_vehicleYearController.text.trim()) ?? 0,
        'vehicleTypes': _selectedVehicleTypes.toList(),
        'documents': {
          'licenseFront': _imageToBase64(_licenseFront),
          'licenseBack': _imageToBase64(_licenseBack),
          'insurance': _imageToBase64(_insurance),
          'idDocument': _imageToBase64(_idDocument),
          'vehiclePhoto': _imageToBase64(_vehiclePhoto),
        },
      };

      final response = await http.post(
        Uri.parse('${AppConfig.serverUrl}/api/drivers/apply'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isSubmitting = false;
          _submittedSuccessfully = true;
        });
      } else {
        throw Exception('فشل إرسال الطلب');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الإرسال: $e')),
      );
    }
  }

  // بناء بطاقة رفع صورة
  Widget _buildUploadCard({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: image == null
            ? Row(
                children: [
                  Icon(Icons.cloud_upload, color: AppTheme.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Icon(Icons.add, color: AppTheme.primary),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      image,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'تم رفع الملف',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  // بناء Chips فئات المركبات
  Widget _buildCategoryChips() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConfig.vehicleCategories.entries.map((entry) {
        final isSelected = _selectedVehicleTypes.contains(entry.key);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedVehicleTypes.remove(entry.key);
              } else {
                _selectedVehicleTypes.add(entry.key);
              }
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary
                  : (isDark ? AppTheme.darkSurface : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.primary : Colors.grey.shade300,
              ),
            ),
            child: Text(
              entry.value,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : AppTheme.textPrimary),
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    if (_submittedSuccessfully) {
      return Scaffold(
        appBar: AppBar(title: Text('طلب الشراكة')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 80),
                SizedBox(height: 24),
                Text(
                  'تم إرسال طلبك بنجاح',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'جاري مراجعة الوثائق من قِبل الإدارة وسيتم تفعيل حسابك في أقرب وقت',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                  },
                  child: Text('العودة للرئيسية'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('طلب الشراكة للسائقين')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== المعلومات الشخصية ==========
              Text(
                'المعلومات الشخصية والمركبة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 16),

              // الاسم الكامل
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
              ),
              SizedBox(height: 12),

              // رقم الهاتف (غير قابل للتعديل)
              TextFormField(
                initialValue: auth.user?.phone ?? '',
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              SizedBox(height: 12),

              // رقم رخصة القيادة
              TextFormField(
                controller: _licenseNumberController,
                decoration: InputDecoration(
                  labelText: 'رقم رخصة القيادة',
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
              ),
              SizedBox(height: 12),

              // تاريخ صلاحية الرخصة
              TextFormField(
                controller: _licenseExpiryController,
                decoration: InputDecoration(
                  labelText: 'تاريخ صلاحية الرخصة (YYYY-MM-DD)',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
              ),
              SizedBox(height: 12),

              // رقم لوحة السطحة
              TextFormField(
                controller: _plateNumberController,
                decoration: InputDecoration(
                  labelText: 'رقم لوحة السطحة',
                  prefixIcon: Icon(Icons.local_shipping),
                ),
                validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
              ),
              SizedBox(height: 12),

              // سنة الصنع
              TextFormField(
                controller: _vehicleYearController,
                decoration: InputDecoration(
                  labelText: 'سنة الصنع',
                  prefixIcon: Icon(Icons.date_range),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
              ),
              SizedBox(height: 16),

              // فئات السطحات المتاحة
              Text(
                'فئات السطحات المتاحة للقطر',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              _buildCategoryChips(),
              SizedBox(height: 24),

              // ========== رفع الوثائق ==========
              Text(
                'رفع الوثائق والثبوتيات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 16),

              _buildUploadCard(
                title: 'رخصة القيادة (الأمام)',
                image: _licenseFront,
                onTap: () async {
                  final img = await _showImagePicker();
                  if (img != null) setState(() => _licenseFront = img);
                },
              ),
              SizedBox(height: 8),
              _buildUploadCard(
                title: 'رخصة القيادة (الخلف)',
                image: _licenseBack,
                onTap: () async {
                  final img = await _showImagePicker();
                  if (img != null) setState(() => _licenseBack = img);
                },
              ),
              SizedBox(height: 8),
              _buildUploadCard(
                title: 'وثيقة التأمين',
                image: _insurance,
                onTap: () async {
                  final img = await _showImagePicker();
                  if (img != null) setState(() => _insurance = img);
                },
              ),
              SizedBox(height: 8),
              _buildUploadCard(
                title: 'بطاقة الهوية / السجل التجاري',
                image: _idDocument,
                onTap: () async {
                  final img = await _showImagePicker();
                  if (img != null) setState(() => _idDocument = img);
                },
              ),
              SizedBox(height: 8),
              _buildUploadCard(
                title: 'صورة السطحة (خارجية)',
                image: _vehiclePhoto,
                onTap: () async {
                  final img = await _showImagePicker();
                  if (img != null) setState(() => _vehiclePhoto = img);
                },
              ),
              SizedBox(height: 24),

              // ========== الشروط والأحكام ==========
              Text(
                'الشروط والأحكام',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'بموجب هذا الطلب، تقر بأن جميع البيانات صحيحة وتوافق على نظام الرصيد المسبق للعمولة. سيتم قبول الطلبات بناءً على توفر رصيد كافٍ في محفظتك لتغطية نسبة التطبيق عن الرحلات النقدية.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() => _agreedToTerms = value ?? false);
                    },
                    activeColor: AppTheme.primary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'أوافق على الشروط والأحكام',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // ========== زر الإرسال ==========
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitApplication,
                  icon: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Icon(Icons.send),
                  label: Text(
                    _isSubmitting ? 'جاري الإرسال...' : 'إرسال طلب الشراكة',
                  ),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
