import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('لوحة التحكم'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'نظرة عامة'),
              Tab(text: 'السائقين'),
              Tab(text: 'العملاء'),
              Tab(text: 'الإعدادات'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OverviewTab(),
            DriversTab(),
            ClientsTab(),
            SettingsTab(),
          ],
        ),
      ),
    );
  }
}

// ========== قسم النظرة العامة ==========
class OverviewTab extends StatefulWidget {
  @override
  _OverviewTabState createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.serverUrl}/api/admin/stats'),
      );
      if (res.statusCode == 200) {
        setState(() {
          _stats = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        throw Exception('فشل التحميل');
      }
    } catch (e) {
      setState(() {
        _error = 'تعذر تحميل الإحصائيات: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }

    return GridView.count(
      crossAxisCount: 2,
      padding: EdgeInsets.all(16),
      children: [
        _buildStatCard('رحلات نشطة', _stats?['active_trips'] ?? 0, Icons.directions_car),
        _buildStatCard('رحلات مكتملة', _stats?['completed_trips'] ?? 0, Icons.check_circle),
        _buildStatCard('سائقون متصلون', _stats?['online_drivers'] ?? 0, Icons.person),
        _buildStatCard('عمولات معلقة', '${_stats?['pending_revenue'] ?? 0} دج', Icons.money),
      ],
    );
  }

  Widget _buildStatCard(String title, value, IconData icon) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primary, size: 32),
            SizedBox(height: 8),
            Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ========== قسم السائقين ==========
class DriversTab extends StatefulWidget {
  @override
  _DriversTabState createState() => _DriversTabState();
}

class _DriversTabState extends State<DriversTab> {
  List<dynamic> _pendingDrivers = [];
  List<dynamic> _approvedDrivers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final pendingRes = await http.get(
        Uri.parse('${AppConfig.serverUrl}/api/admin/drivers/pending'),
      );
      final approvedRes = await http.get(
        Uri.parse('${AppConfig.serverUrl}/api/admin/drivers/approved'),
      );

      if (pendingRes.statusCode == 200 && approvedRes.statusCode == 200) {
        setState(() {
          _pendingDrivers = jsonDecode(pendingRes.body) as List;
          _approvedDrivers = jsonDecode(approvedRes.body) as List;
          _isLoading = false;
        });
      } else {
        throw Exception('فشل التحميل');
      }
    } catch (e) {
      setState(() { _error = 'تعذر تحميل السائقين: $e'; _isLoading = false; });
    }
  }

  Future<void> _decideDriver(int driverId, String decision) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.serverUrl}/api/admin/drivers/decision'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'driverId': driverId, 'decision': decision}),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم التحديث')),
        );
        _loadDrivers();
      } else {
        throw Exception('فشل');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e')),
      );
    }
  }

  Future<void> _chargeWallet(String phone, double amount) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.serverUrl}/api/admin/wallets/charge'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'amount': amount}),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم شحن الرصيد')),
        );
        _loadDrivers();
      } else {
        throw Exception('فشل');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e')),
      );
    }
  }

  void _showChargeDialog(dynamic driver) {
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('شحن رصيد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('رقم الهاتف: ${driver['phone']}'),
            SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'المبلغ (دج)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                Navigator.pop(ctx);
                _chargeWallet(driver['phone'], amount);
              }
            },
            child: Text('شحن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Text('طلبات الشراكة المعلقة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 8),
        if (_pendingDrivers.isEmpty)
          Text('لا توجد طلبات')
        else
          ..._pendingDrivers.map((driver) => Card(
                child: ListTile(
                  title: Text(driver['users']['name'] ?? 'غير معروف'),
                  subtitle: Text('الهاتف: ${driver['users']['phone']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () => _decideDriver(driver['id'], 'approve'),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => _decideDriver(driver['id'], 'reject'),
                      ),
                    ],
                  ),
                ),
              )),
        SizedBox(height: 24),
        Text('السائقون النشطون', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 8),
        if (_approvedDrivers.isEmpty)
          Text('لا يوجد سائقون')
        else
          ..._approvedDrivers.map((driver) => Card(
                child: ListTile(
                  title: Text(driver['users']['name'] ?? 'غير معروف'),
                  subtitle: Text('الهاتف: ${driver['users']['phone']} | الرصيد: ${driver['wallet_balance']} دج'),
                  trailing: IconButton(
                    icon: Icon(Icons.attach_money),
                    onPressed: () => _showChargeDialog(driver['users']),
                  ),
                ),
              )),
      ],
    );
  }
}

// ========== قسم العملاء ==========
class ClientsTab extends StatefulWidget {
  @override
  _ClientsTabState createState() => _ClientsTabState();
}

class _ClientsTabState extends State<ClientsTab> {
  List<dynamic> _clients = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.serverUrl}/api/admin/clients'),
      );
      if (res.statusCode == 200) {
        setState(() {
          _clients = jsonDecode(res.body) as List;
          _isLoading = false;
        });
      } else {
        throw Exception('فشل');
      }
    } catch (e) {
      setState(() { _error = 'تعذر تحميل العملاء: $e'; _isLoading = false; });
    }
  }

  Future<void> _toggleBlock(int userId, bool block) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.serverUrl}/api/admin/clients/block'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'block': block}),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم التحديث')),
        );
        _loadClients();
      } else {
        throw Exception('فشل');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _clients.length,
      itemBuilder: (ctx, index) {
        final client = _clients[index];
        final isBlocked = client['blocked'] ?? false;
        return Card(
          child: ListTile(
            leading: Icon(Icons.person, color: AppTheme.primary),
            title: Text(client['phone']),
            subtitle: Text('الاسم: ${client['name'] ?? 'غير محدد'}'),
            trailing: IconButton(
              icon: Icon(isBlocked ? Icons.block : Icons.check_circle,
                  color: isBlocked ? Colors.red : Colors.green),
              onPressed: () => _toggleBlock(client['id'], !isBlocked),
            ),
          ),
        );
      },
    );
  }
}

// ========== قسم الإعدادات ==========
class SettingsTab extends StatefulWidget {
  @override
  _SettingsTabState createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _commissionController = TextEditingController();
  final _minBalanceController = TextEditingController();
  final _priceMotoController = TextEditingController();
  final _priceCarController = TextEditingController();
  final _priceTruckController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // يمكن تحميل الإعدادات من الخادم لاحقًا
    _commissionController.text = '15';
    _minBalanceController.text = '500';
    _priceMotoController.text = '300';
    _priceCarController.text = '500';
    _priceTruckController.text = '900';
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.serverUrl}/api/admin/settings/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'commission_rate': double.tryParse(_commissionController.text) ?? 15,
          'min_wallet_balance': double.tryParse(_minBalanceController.text) ?? 500,
          'price_per_km_motorcycle': double.tryParse(_priceMotoController.text) ?? 300,
          'price_per_km_car': double.tryParse(_priceCarController.text) ?? 500,
          'price_per_km_truck': double.tryParse(_priceTruckController.text) ?? 900,
        }),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم الحفظ')),
        );
      } else {
        throw Exception('فشل');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _commissionController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'نسبة العمولة (%)'),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _minBalanceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'الحد الأدنى لرصيد السائق (دج)'),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _priceMotoController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'سعر الكيلومتر - دراجة (دج)'),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _priceCarController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'سعر الكيلومتر - سياحية/نفعية (دج)'),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _priceTruckController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'سعر الكيلومتر - شاحنة (دج)'),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveSettings,
            child: _isLoading
                ? CircularProgressIndicator()
                : Text('حفظ الإعدادات'),
          ),
        ],
      ),
    );
  }
}
