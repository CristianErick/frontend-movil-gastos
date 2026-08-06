import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import 'profile_goals_screen.dart';
import 'login_screen.dart';
import '../widgets/transaction_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  double _totalIncome = 0;
  double _totalExpense = 0;
  List<TransactionModel> _transactions = [];
  bool _loading = true;
  String? _error;

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  int _selectedNavIndex = 0;

  String _searchQuery = '';
  String? _selectedType;
  int? _selectedCategoryId;
  String _dateFilter = 'all';

  List<CategoryModel> _categories = [];
  double? _monthlyBudgetLimit;
  double _currentMonthExpenses = 0;

  final _searchController = TextEditingController();

  late AnimationController _fabController;
  late AnimationController _balanceController;
  late Animation<double> _fabAnimation;
  late Animation<double> _balanceAnimation;

  double get _balance => _totalIncome - _totalExpense;

  List<TransactionModel> get _filteredTransactions {
    var result = _transactions.toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((t) => t.description.toLowerCase().contains(q)).toList();
    }

    if (_selectedType != null) {
      result = result.where((t) => t.type == _selectedType).toList();
    }

    if (_selectedCategoryId != null) {
      result = result.where((t) => t.categoryId == _selectedCategoryId).toList();
    }

    if (_dateFilter != 'all') {
      final now = DateTime.now();
      DateTime start;
      switch (_dateFilter) {
        case 'this_month':
          start = DateTime(now.year, now.month, 1);
          break;
        case 'last_month':
          start = DateTime(now.year, now.month - 1, 1);
          final end = DateTime(now.year, now.month, 1);
          result = result.where((t) => t.date.isAfter(start.subtract(const Duration(days: 1))) && t.date.isBefore(end)).toList();
          return result;
        case 'last_3_months':
          start = DateTime(now.year, now.month - 3, 1);
          break;
        default:
          start = DateTime(2000);
      }
      result = result.where((t) => t.date.isAfter(start.subtract(const Duration(days: 1)))).toList();
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _balanceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(parent: _fabController, curve: Curves.elasticOut);
    _balanceAnimation = CurvedAnimation(parent: _balanceController, curve: Curves.easeOutCubic);
    _loadData();
    _fabController.forward();
    _balanceController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getTransactions(),
        ApiService.getProfile(),
        ApiService.getCategories(),
      ]);

      final txnResponse = results[0];
      final profileResponse = results[1];
      final catResponse = results[2];

      final dataList = txnResponse['data'];
      if (dataList is List) {
        final transactions = dataList
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();

        double income = 0, expense = 0;
        double monthExpense = 0;
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);

        for (final t in transactions) {
          if (t.type == 'income') {
            income += t.amount;
          } else {
            expense += t.amount;
            if (t.date.isAfter(monthStart.subtract(const Duration(days: 1)))) {
              monthExpense += t.amount;
            }
          }
        }

        setState(() {
          _totalIncome = income;
          _totalExpense = expense;
          _transactions = transactions;
          _currentMonthExpenses = monthExpense;
        });
        _balanceController.forward(from: 0);
      } else {
        setState(() {
          _totalIncome = 0;
          _totalExpense = 0;
          _transactions = [];
          _currentMonthExpenses = 0;
        });
      }

      final profile = profileResponse['user']?['profile'];
      if (profile != null) {
        final budget = _toDouble(profile['monthly_budget_limit']);
        setState(() => _monthlyBudgetLimit = budget);
      }

      final catList = catResponse['categories'] as List?;
      if (catList != null) {
        setState(() => _categories = catList.map((e) => CategoryModel.fromJson(e)).toList());
      }
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
      setState(() {
        final msg = e.toString();
        _error = msg.length > 200 ? msg.substring(0, 200) : msg;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await ApiService.removeToken();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _showAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionForm(onSuccess: _loadData),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedType = null;
      _selectedCategoryId = null;
      _dateFilter = 'all';
      _searchController.clear();
    });
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedType != null ||
      _selectedCategoryId != null ||
      _dateFilter != 'all';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [cs.primary, cs.secondary],
          ).createShader(bounds),
          child: const Text(
            'OptiGasto',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, tp, _) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: AnimatedRotation(
                  turns: tp.themeMode == ThemeMode.dark ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    tp.themeMode == ThemeMode.dark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                    color: cs.onSurface,
                  ),
                ),
                onPressed: tp.toggle,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.logout_rounded, color: cs.onSurface),
              onPressed: _logout,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: cs.primary,
        backgroundColor: cs.surface,
        child: _loading
            ? _buildLoadingState(cs)
            : _error != null
                ? _buildErrorState(cs)
                : CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildSearchBar(cs, isDark)),
                      SliverToBoxAdapter(child: _buildFilterChips(cs)),
                      if (_monthlyBudgetLimit != null && _monthlyBudgetLimit! > 0)
                        SliverToBoxAdapter(child: _buildBudgetProgress(cs, isDark)),
                      SliverToBoxAdapter(child: _buildBalanceCard(cs, isDark)),
                      SliverToBoxAdapter(child: _buildTransactionsHeader(cs)),
                      _filteredTransactions.isEmpty
                          ? SliverFillRemaining(child: _buildEmptyState(cs, isDark))
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final t = _filteredTransactions[index];
                                  return _buildTransactionTile(t, cs, isDark, index);
                                },
                                childCount: _filteredTransactions.length,
                              ),
                            ),
                    ],
                  ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _showAddTransactionSheet,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text('Nueva', style: TextStyle(fontWeight: FontWeight.w600)),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _buildBottomNav(cs),
    );
  }

  Widget _buildLoadingState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: cs.primary, strokeWidth: 3),
          const SizedBox(height: 20),
          Text(
            'Cargando tus finanzas...',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme cs) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cloud_off_rounded, size: 64, color: cs.onErrorContainer),
              ),
              const SizedBox(height: 24),
              Text(
                'Sin conexión',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
],
        ),
      ),
    ),
    );
  }

  Widget _buildSearchBar(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _searchQuery.isNotEmpty ? cs.primary.withValues(alpha: 0.5) : cs.outlineVariant,
          ),
        ),
        child: SearchBar(
          controller: _searchController,
          hintText: 'Buscar transacciones...',
          leading: Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
          trailing: [
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
          ],
          onChanged: (v) => setState(() => _searchQuery = v),
          elevation: WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          textStyle: WidgetStatePropertyAll(TextStyle(color: cs.onSurface)),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ColorScheme cs) {
    final typeFilters = ['income', 'expense'];
    final dateFilters = [
      ('all', 'Todo'),
      ('this_month', 'Este mes'),
      ('last_month', 'Mes pasado'),
      ('last_3_months', '3 meses'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final type in typeFilters) ...[
                  _buildStyledFilterChip(
                    cs,
                    label: type == 'income' ? 'Ingresos' : 'Gastos',
                    icon: type == 'income' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    selected: _selectedType == type,
                    onSelected: (v) => setState(() => _selectedType = v ? type : null),
                    selectedColor: type == 'income' ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 10),
                ],
                for (final (key, label) in dateFilters) ...[
                  _buildStyledFilterChip(
                    cs,
                    label: label,
                    selected: _dateFilter == key,
                    onSelected: (v) => setState(() => _dateFilter = v ? key : 'all'),
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          if (_categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final cat in _categories) ...[
                    _buildCategoryChip(cs, cat),
                    const SizedBox(width: 10),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStyledFilterChip(
    ColorScheme cs, {
    required String label,
    IconData? icon,
    required bool selected,
    required void Function(bool) onSelected,
    Color? selectedColor,
  }) {
    final color = selectedColor ?? cs.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.white : color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.white : cs.onSurface,
              ),
            ),
          ],
        ),
        selected: selected,
        onSelected: onSelected,
        selectedColor: color,
        checkmarkColor: Colors.white,
        backgroundColor: cs.surfaceContainerHighest,
        side: BorderSide(
          color: selected ? color : cs.outlineVariant,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildCategoryChip(ColorScheme cs, CategoryModel cat) {
    final selected = _selectedCategoryId == cat.id;
    final color = Color(int.tryParse(cat.color?.replaceFirst('#', '0xFF') ?? '0xFF6366F1') ?? 0xFF6366F1);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        avatar: CircleAvatar(
          radius: 10,
          backgroundColor: selected ? Colors.white : color.withValues(alpha: 0.2),
          child: selected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
        ),
        label: Text(
          cat.name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : cs.onSurface,
          ),
        ),
        selected: selected,
        onSelected: (v) => setState(() => _selectedCategoryId = v ? cat.id : null),
        selectedColor: color,
        backgroundColor: cs.surfaceContainerHighest,
        side: BorderSide(
          color: selected ? color : cs.outlineVariant,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildBudgetProgress(ColorScheme cs, bool isDark) {
    final budget = _monthlyBudgetLimit!;
    final ratio = budget > 0 ? (_currentMonthExpenses / budget).clamp(0.0, 1.0) : 0.0;
    final percent = (ratio * 100).toStringAsFixed(0);
    final color = ratio < 0.5 ? Colors.green : (ratio < 0.8 ? Colors.orange : Colors.red);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.account_balance_wallet_rounded, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Presupuesto Mensual', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                        Text(
                          'S/ ${budget.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$percent%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  width: MediaQuery.of(context).size.width * ratio - 40,
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gastado este mes: S/ ${_currentMonthExpenses.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                Text(
                  'Restante: S/ ${(budget - _currentMonthExpenses).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: AnimatedBuilder(
        animation: _balanceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.95 + (0.05 * _balanceAnimation.value),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF1E1E2E),
                      const Color(0xFF25253A),
                    ]
                  : [
                      Colors.white,
                      cs.primary.withValues(alpha: 0.03),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF33334D) : cs.outlineVariant,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: cs.shadow.withValues(alpha: isDark ? 0.1 : 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _balance >= 0
                            ? [Colors.green.shade400, Colors.green.shade600]
                            : [Colors.red.shade400, Colors.red.shade600],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _balance >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saldo Actual', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          'S/ ${_balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildStatItem(cs, 'Ingresos', _totalIncome, Colors.green, Icons.arrow_downward_rounded)),
                  Container(height: 48, width: 1, color: cs.outlineVariant),
                  Expanded(child: _buildStatItem(cs, 'Gastos', _totalExpense, Colors.red, Icons.arrow_upward_rounded)),
                  Container(height: 48, width: 1, color: cs.outlineVariant),
                  Expanded(child: _buildStatItem(cs, 'Transacciones', _transactions.length.toDouble(), cs.primary, Icons.receipt_long_rounded, isCount: true)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(ColorScheme cs, String label, double value, Color color, IconData icon, {bool isCount = false}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          isCount ? value.toInt().toString() : 'S/ ${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTransactionsHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt_long_rounded, color: cs.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Transacciones',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (_hasActiveFilters)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: const Text('Limpiar'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _hasActiveFilters ? Icons.search_off_rounded : Icons.receipt_long_rounded,
                size: 56,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _hasActiveFilters ? 'Sin resultados' : 'No hay transacciones',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasActiveFilters
                  ? 'Intenta cambiar los filtros o la búsqueda'
                  : 'Presiona el botón + para agregar tu primera transacción',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, height: 1.5, fontSize: 15),
            ),
            if (!_hasActiveFilters) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _showAddTransactionSheet,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar transacción'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(TransactionModel t, ColorScheme cs, bool isDark, int index) {
    final color = t.type == 'income' ? Colors.green : Colors.red;
    final bgColor = isDark
        ? (t.type == 'income' ? Colors.green.shade900 : Colors.red.shade900)
        : (t.type == 'income' ? Colors.green.shade50 : Colors.red.shade50);

    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 50).clamp(0, 300)),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  t.type == 'income' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              title: Text(
                t.description,
                style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    if (t.category?.color != null)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Color(int.tryParse(t.category!.color!.replaceFirst('#', '0xFF')) ?? 0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (t.category?.color != null) const SizedBox(width: 8),
                    Text(
                      t.category?.name ?? 'Sin categoría',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${t.type == 'income' ? '+' : '-'}' + 'S/ ${t.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM').format(t.date),
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant, width: 1)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(cs, 0, Icons.home_rounded, Icons.home_outlined, 'Inicio'),
              _buildNavItem(cs, 1, Icons.person_rounded, Icons.person_outline, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(ColorScheme cs, int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final selected = _selectedNavIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            if (index == 1) {
              await Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const ProfileGoalsScreen(),
                  transitionsBuilder: (_, animation, __, child) {
                    return SlideTransition(
                      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
                        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                      ),
                      child: child,
                    );
                  },
                ),
              );
              _loadData();
            }
            setState(() => _selectedNavIndex = index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? cs.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? activeIcon : inactiveIcon,
                  color: selected ? Colors.white : cs.onSurfaceVariant,
                  size: 22,
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField(
    ColorScheme cs, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool readOnly = false,
    bool filled = false,
    TextInputType? keyboardType,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      style: TextStyle(color: cs.onSurface, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: cs.onSurfaceVariant),
        filled: filled,
        fillColor: filled ? cs.surfaceContainerHighest : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        labelStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500),
        floatingLabelStyle: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPrimaryButton(
    ColorScheme cs, {
    required String label,
    required VoidCallback? onPressed,
    required bool loading,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
    ColorScheme cs, {
    required String label,
    required VoidCallback? onPressed,
    required bool loading,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        style: FilledButton.styleFrom(
          backgroundColor: cs.secondary,
          foregroundColor: cs.onSecondary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildIconButton(
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}