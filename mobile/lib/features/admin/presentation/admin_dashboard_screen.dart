import 'package:flutter/material.dart';
import '../../../app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_common_widgets.dart';
import '../data/admin_repository.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة التحكم'),
          bottom: const TabBar(tabs: [
            Tab(text: 'نظرة عامة'),
            Tab(text: 'السائقون'),
            Tab(text: 'العملاء'),
            Tab(text: 'الإعدادات'),
          ]),
        ),
        body: const TabBarView(children: [_OverviewTab(), _DriversTab(), _ClientsTab(), _SettingsTab()]),
      ),
    );
  }
}

class _OverviewTab extends StatefulWidget {
  const _OverviewTab();
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  final _repository = AdminRepository();
  Map<String, dynamic>? _stats;
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
    final result = await _repository.getStats();
    if (!mounted) return;
    result.when(
      success: (data) => setState(() {
        _stats = data;
        _isLoading = false;
      }),
      failure: (f) => setState(() {
        _error = f.message;
        _isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const AppLoadingView();
    if (_error != null) return AppEmptyState(icon: Icons.error_outline_rounded, title: 'تعذر تحميل الإحصائيات', subtitle: _error);

    final colors = context.colors;
    final items = [
      ('رحلات نشطة', _stats?['active_trips'] ?? 0, Icons.directions_car_rounded),
      ('رحلات مكتملة', _stats?['completed_trips'] ?? 0, Icons.check_circle_rounded),
      ('سائقون معتمدون', _stats?['online_drivers'] ?? 0, Icons.person_rounded),
      ('عمولات محصّلة', '${_stats?['pending_revenue'] ?? 0} ${AppConfig.currency}', Icons.payments_rounded),
    ];

    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(AppSpacing.lg),
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.3,
        children: items.map((item) {
          return AppCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.$3, color: AppColors.primary, size: 30),
                const SizedBox(height: AppSpacing.sm),
                Text('${item.$2}', style: AppTextStyles.headline(colors.textPrimary)),
                const SizedBox(height: 4),
                Text(item.$1, style: AppTextStyles.bodySmall(colors.textSecondary), textAlign: TextAlign.center),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DriversTab extends StatefulWidget {
  const _DriversTab();
  @override
  State<_DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends State<_DriversTab> {
  final _repository = AdminRepository();
  List<dynamic> _pending = [];
  List<dynamic> _approved = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final pendingResult = await _repository.getPendingDrivers();
    final approvedResult = await _repository.getApprovedDrivers();
    if (!mounted) return;

    setState(() {
      pendingResult.when(success: (d) => _pending = d, failure: (_) => _pending = []);
      approvedResult.when(success: (d) => _approved = d, failure: (_) => _approved = []);
      _isLoading = false;
    });
  }

  Future<void> _decide(String driverId, String decision) async {
    await _repository.decideDriver(driverId, decision);
    _load();
  }

  void _showChargeDialog(Map driverUser) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('شحن رصيد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الهاتف: ${driverUser['phone']}'),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount <= 0) return;
              Navigator.pop(dialogContext);
              await _repository.chargeWallet(driverUser['phone'], amount);
              _load();
            },
            child: const Text('شحن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const AppLoadingView();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('طلبات معلّقة', style: AppTextStyles.title(context.colors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          if (_pending.isEmpty)
            Text('لا توجد طلبات', style: AppTextStyles.bodyMedium(context.colors.textSecondary))
          else
            ..._pending.map((driver) => AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(driver['users']?['name'] ?? 'غير معروف'),
                    subtitle: Text(driver['users']?['phone'] ?? ''),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.check_circle, color: AppColors.success), onPressed: () => _decide(driver['id'], 'approve')),
                      IconButton(icon: const Icon(Icons.cancel, color: AppColors.error), onPressed: () => _decide(driver['id'], 'reject')),
                    ]),
                  ),
                )),
          const SizedBox(height: AppSpacing.xl),
          Text('السائقون المعتمدون', style: AppTextStyles.title(context.colors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          if (_approved.isEmpty)
            Text('لا يوجد سائقون', style: AppTextStyles.bodyMedium(context.colors.textSecondary))
          else
            ..._approved.map((driver) => AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(driver['users']?['name'] ?? 'غير معروف'),
                    subtitle: Text('الرصيد: ${driver['wallet_balance']} ${AppConfig.currency}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.attach_money_rounded, color: AppColors.primary),
                      onPressed: () => _showChargeDialog(driver['users']),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class _ClientsTab extends StatefulWidget {
  const _ClientsTab();
  @override
  State<_ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<_ClientsTab> {
  final _repository = AdminRepository();
  List<dynamic> _clients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _repository.getClients();
    if (!mounted) return;
    result.when(
      success: (d) => setState(() {
        _clients = d;
        _isLoading = false;
      }),
      failure: (_) => setState(() => _isLoading = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const AppLoadingView();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _clients.length,
        itemBuilder: (context, index) {
          final client = _clients[index];
          final isBlocked = client['blocked'] ?? false;
          return AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_rounded, color: AppColors.primary),
              title: Text(client['phone']),
              subtitle: Text('الاسم: ${client['name'] ?? 'غير محدد'}'),
              trailing: IconButton(
                icon: Icon(isBlocked ? Icons.block_rounded : Icons.check_circle_rounded, color: isBlocked ? AppColors.error : AppColors.success),
                onPressed: () async {
                  await _repository.toggleBlockClient(client['id'], !isBlocked);
                  _load();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();
  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final _repository = AdminRepository();
  final _commission = TextEditingController(text: '15');
  final _minBalance = TextEditingController(text: '500');
  final _priceMoto = TextEditingController(text: '300');
  final _priceCar = TextEditingController(text: '500');
  final _priceTruck = TextEditingController(text: '900');
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await _repository.updateSettings({
      'commission_rate': double.tryParse(_commission.text) ?? 15,
      'min_wallet_balance': double.tryParse(_minBalance.text) ?? 500,
      'price_per_km_motorcycle': double.tryParse(_priceMoto.text) ?? 300,
      'price_per_km_car': double.tryParse(_priceCar.text) ?? 500,
      'price_per_km_truck': double.tryParse(_priceTruck.text) ?? 900,
    });
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ')));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          TextField(controller: _commission, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'نسبة العمولة (%)')),
          const SizedBox(height: AppSpacing.md),
          TextField(controller: _minBalance, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الحد الأدنى للرصيد')),
          const SizedBox(height: AppSpacing.md),
          TextField(controller: _priceMoto, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر الكم - دراجة')),
          const SizedBox(height: AppSpacing.md),
          TextField(controller: _priceCar, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر الكم - سيارة')),
          const SizedBox(height: AppSpacing.md),
          TextField(controller: _priceTruck, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر الكم - شاحنة')),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(onPressed: _isSaving ? null : _save, child: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ الإعدادات')),
        ],
      ),
    );
  }
}
