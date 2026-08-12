import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../providers/auth_provider.dart';
import '../theme.dart';
import '../config.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _vehicleFormKey = GlobalKey<FormState>();

  String? _avatarPath;
  List<Vehicle> _vehicles = [];

  // حقول نموذج المركبة
  String _vehicleCategory = 'car';
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // تحميل البيانات المحفوظة
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final user = context.read<AuthProvider>().user;
    _nameController.text = user?.name ?? '';

    setState(() {
      _avatarPath = prefs.getString('avatar_path');
      _vehicles = loadVehicles(prefs);
    });
  }

  // حفظ الاسم
  Future<void> _saveName() async {
    final auth = context.read<AuthProvider>();
    await auth.updateProfile(
      name: _nameController.text.trim(),
      email: auth.user?.email ?? '',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حفظ الاسم')),
    );
  }

  // تغيير الصورة الشخصية
  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (image != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('avatar_path', image.path);
      setState(() {
        _avatarPath = image.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث الصورة')),
      );
    }
  }

  // فتح نافذة إضافة مركبة
  void _showAddVehicleSheet() {
    _modelController.clear();
    _plateController.clear();
    _colorController.clear();
    _vehicleCategory = 'car';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: _vehicleFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إضافة مركبة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 16),
                    // اختيار الفئة
                    DropdownButtonFormField<String>(
                      initialValue: _vehicleCategory,
                      decoration: InputDecoration(labelText: 'الفئة'),
                      items: AppConfig.vehicleCategories.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _vehicleCategory = value ?? 'car';
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _modelController,
                      decoration: InputDecoration(labelText: 'الموديل'),
                      validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _plateController,
                      decoration: InputDecoration(labelText: 'رقم اللوحة'),
                      validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _colorController,
                      decoration: InputDecoration(labelText: 'اللون'),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _saveVehicle(context),
                        child: Text('حفظ المركبة'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // حفظ مركبة جديدة
  Future<void> _saveVehicle(BuildContext sheetContext) async {
    if (!_vehicleFormKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final vehicle = Vehicle(
      category: _vehicleCategory,
      model: _modelController.text.trim(),
      plate: _plateController.text.trim(),
      color: _colorController.text.trim(),
    );

    _vehicles.add(vehicle);
    await saveVehicles(prefs, _vehicles);

    if (!mounted) return;
    Navigator.pop(sheetContext);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تمت إضافة المركبة')),
    );
  }

  // حذف مركبة
  Future<void> _deleteVehicle(int index) async {
    final prefs = await SharedPreferences.getInstance();
    _vehicles.removeAt(index);
    await saveVehicles(prefs, _vehicles);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('الملف الشخصي')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: 20),

            // صورة البروفايل
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  backgroundImage: _avatarPath != null
                      ? FileImage(File(_avatarPath!))
                      : null,
                  child: _avatarPath == null
                      ? Icon(Icons.person, size: 80, color: AppTheme.primary)
                      : null,
                ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: GestureDetector(
                    onTap: _changeAvatar,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // قسم البيانات
            Card(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الاسم
                    Text(
                      'الاسم الكامل',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'أدخل اسمك',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.save, color: AppTheme.primary),
                          onPressed: _saveName,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // رقم الهاتف
                    Text(
                      'رقم الهاتف',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      initialValue: auth.user?.phone ?? '',
                      readOnly: true,
                      decoration: InputDecoration(
                        suffixIcon: Icon(Icons.lock, color: AppTheme.primary),
                        hintText: 'رقم الهاتف',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // قسم المركبات
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'مركباتي',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: _showAddVehicleSheet,
                  icon: Icon(Icons.add_circle, color: AppTheme.primary),
                  iconSize: 30,
                ),
              ],
            ),
            SizedBox(height: 8),

            // قائمة المركبات
            if (_vehicles.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(Icons.directions_car, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'لا توجد مركبات محفوظة',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_vehicles.length, (index) {
                final vehicle = _vehicles[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  child: ListTile(
                    leading: Icon(
                      _getVehicleIcon(vehicle.category),
                      color: AppTheme.primary,
                    ),
                    title: Text(
                      '${AppConfig.vehicleCategories[vehicle.category] ?? vehicle.category} - ${vehicle.model}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'لوحة: ${vehicle.plate}' +
                          (vehicle.color.isNotEmpty ? ' | لون: ${vehicle.color}' : ''),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: AppTheme.error),
                      onPressed: () => _deleteVehicle(index),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  IconData _getVehicleIcon(String category) {
    switch (category) {
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'car':
        return Icons.directions_car;
      case 'utility':
        return Icons.car_rental;
      case 'truck':
        return Icons.local_shipping;
      case 'heavy_truck':
        return Icons.fire_truck;
      default:
        return Icons.directions_car;
    }
  }
}

// نموذج مركبة بسيط للتخزين المحلي
class Vehicle {
  final String category;
  final String model;
  final String plate;
  final String color;

  Vehicle({
    required this.category,
    required this.model,
    required this.plate,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'model': model,
        'plate': plate,
        'color': color,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        category: json['category'] ?? 'car',
        model: json['model'] ?? '',
        plate: json['plate'] ?? '',
        color: json['color'] ?? '',
      );
}

// حفظ قائمة المركبات في SharedPreferences
Future<void> saveVehicles(SharedPreferences prefs, List<Vehicle> vehicles) async {
  final list = vehicles.map((v) => v.toJson()).toList();
  await prefs.setString('vehicles', jsonEncode(list));
}

// تحميل قائمة المركبات من SharedPreferences
List<Vehicle> loadVehicles(SharedPreferences prefs) {
  final raw = prefs.getString('vehicles');
  if (raw == null) return [];
  final list = jsonDecode(raw) as List;
  return list.map((json) => Vehicle.fromJson(json)).toList();
}
