import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController.text = auth.user?.name ?? '';
    _emailController.text = auth.user?.email ?? '';
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthProvider>();
    await auth.updateProfile(
      name: _nameController.text,
      email: _emailController.text,
    );
    setState(() {
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حفظ الملف الشخصي')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('الملف الشخصي')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: 24),
            // صورة المستخدم
            CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child: Icon(Icons.person, size: 80, color: AppTheme.primary),
            ),
            SizedBox(height: 24),
            // معلومات المستخدم
            if (!_isEditing) ...[
              ListTile(
                leading: Icon(Icons.phone, color: AppTheme.primary),
                title: Text('رقم الهاتف'),
                subtitle: Text(auth.user?.phone ?? ''),
              ),
              ListTile(
                leading: Icon(Icons.person_outline, color: AppTheme.primary),
                title: Text('الاسم'),
                subtitle: Text(auth.user?.name ?? 'غير محدد'),
              ),
              ListTile(
                leading: Icon(Icons.email_outlined, color: AppTheme.primary),
                title: Text('البريد الإلكتروني'),
                subtitle: Text(auth.user?.email ?? 'غير محدد'),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _toggleEdit,
                icon: Icon(Icons.edit),
                label: Text('تعديل الملف الشخصي'),
              ),
            ] else ...[
              // نموذج التعديل
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'الاسم',
                  filled: true,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  filled: true,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      child: Text('حفظ'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _toggleEdit,
                      child: Text('إلغاء'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
