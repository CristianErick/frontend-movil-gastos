import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';

class ProfileGoalsScreen extends StatefulWidget {
  const ProfileGoalsScreen({super.key});

  @override
  State<ProfileGoalsScreen> createState() => _ProfileGoalsScreenState();
}

class _ProfileGoalsScreenState extends State<ProfileGoalsScreen> with TickerProviderStateMixin {
  final _currencyController = TextEditingController();
  final _budgetController = TextEditingController();
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _goalTitleController = TextEditingController();
  final _goalTargetController = TextEditingController();
  final _goalCurrentController = TextEditingController();
  DateTime _goalDeadline = DateTime.now().add(const Duration(days: 30));

  List<SavingsGoalModel> _goals = [];
  bool _loading = true;
  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _uploadingAvatar = false;
  String? _avatarBase64;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _loadData();
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _currencyController.dispose();
    _budgetController.dispose();
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _goalTitleController.dispose();
    _goalTargetController.dispose();
    _goalCurrentController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final profileResponse = await ApiService.getProfile();
      final profile = profileResponse['user']?['profile'];
      final user = profileResponse['user'];
      if (profile != null) {
        _currencyController.text = profile['currency'] ?? 'PEN';
        _budgetController.text = (profile['monthly_budget_limit'] ?? '').toString();
      }
      if (user != null) {
        _nameController.text = user['name'] ?? '';
        _avatarBase64 = user['avatar'];
      }

      final goalsResponse = await ApiService.getSavingsGoals();
      setState(() {
        _goals = (goalsResponse['savings_goals'] as List)
            .map((e) => SavingsGoalModel.fromJson(e))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al cargar datos: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('El nombre no puede estar vacío', Colors.red);
      return;
    }
    setState(() => _savingProfile = true);
    try {
      await ApiService.updateProfile({
        'currency': _currencyController.text,
        'monthly_budget_limit': double.tryParse(_budgetController.text),
      });
      await ApiService.updateUserName(_nameController.text.trim());
      if (mounted) {
        _showSnackBar('Perfil actualizado correctamente', Colors.green);
        _loadData();
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error al guardar: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar('Completa todos los campos', Colors.red);
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('Las contraseñas no coinciden', Colors.red);
      return;
    }
    if (_newPasswordController.text.length < 8) {
      _showSnackBar('La contraseña debe tener al menos 8 caracteres', Colors.red);
      return;
    }
    setState(() => _savingPassword = true);
    try {
      await ApiService.updateUserPassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        newPasswordConfirmation: _confirmPasswordController.text,
      );
      if (mounted) {
        _showSnackBar('Contraseña cambiada correctamente', Colors.green);
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error al cambiar contraseña: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final extension = picked.name.split('.').last.toLowerCase();
    final base64Image = 'data:image/$extension;base64,${base64Encode(bytes)}';

    setState(() {
      _uploadingAvatar = true;
      _avatarBase64 = base64Image;
    });

    try {
      await ApiService.updateUserAvatar(base64Image);
      if (mounted) _showSnackBar('Foto de perfil actualizada', Colors.green);
    } catch (e) {
      if (mounted) _showSnackBar('Error al subir foto: $e', Colors.red);
      setState(() => _avatarBase64 = null);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _createGoal() async {
    if (_goalTitleController.text.trim().isEmpty) {
      _showSnackBar('Ingresa un título', Colors.red);
      return;
    }
    final target = double.tryParse(_goalTargetController.text);
    if (target == null || target <= 0) {
      _showSnackBar('Monto objetivo inválido', Colors.red);
      return;
    }
    final current = double.tryParse(_goalCurrentController.text) ?? 0;

    try {
      await ApiService.createSavingsGoal({
        'title': _goalTitleController.text.trim(),
        'target_amount': target,
        'current_amount': current,
        'deadline': DateFormat('yyyy-MM-dd').format(_goalDeadline),
      });
      if (mounted) {
        _showSnackBar('Meta creada', Colors.green);
        _goalTitleController.clear();
        _goalTargetController.clear();
        _goalCurrentController.clear();
        setState(() => _goalDeadline = DateTime.now().add(const Duration(days: 30)));
        _loadData();
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _deleteGoal(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar meta'),
        content: const Text('¿Estás seguro de que deseas eliminar esta meta de ahorro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.deleteSavingsGoal(id);
      if (mounted) {
        _showSnackBar('Meta eliminada', Colors.green);
        _loadData();
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', Colors.red);
    }
  }

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
            'Perfil y Metas',
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
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary.withValues(alpha: 0.08),
                cs.secondary.withValues(alpha: 0.04),
              ],
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: cs.primary,
            backgroundColor: cs.surface,
            child: _loading
                ? _buildLoadingState(cs)
                : CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildProfileSection(cs, isDark)),
                      SliverToBoxAdapter(child: _buildPasswordSection(cs, isDark)),
                      SliverToBoxAdapter(child: _buildPreferencesSection(cs, isDark)),
                      SliverToBoxAdapter(child: _buildSavingsGoalsSection(cs, isDark)),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
          ),
        ),
      ),
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
            'Cargando tu perfil...',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primaryContainer.withValues(alpha: 0.3),
                  cs.secondaryContainer.withValues(alpha: 0.2),
                  cs.surface,
                ],
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Mi Perfil', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    GestureDetector(
                      onTap: _pickAndUploadAvatar,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _avatarBase64 != null && _avatarBase64!.startsWith('data:image')
                                ? [Colors.transparent, Colors.transparent]
                                : [cs.primary, cs.secondary],
                          ),
                          border: Border.all(color: cs.primary.withValues(alpha: 0.3), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_avatarBase64 != null && _avatarBase64!.startsWith('data:image'))
                              ClipOval(
                                child: Image.memory(
                                  Uint8List.fromList(base64Decode(_avatarBase64!.split(',').last)),
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Text(
                                _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            if (_uploadingAvatar)
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: cs.primary.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _uploadingAvatar ? Icons.hourglass_empty_rounded : Icons.camera_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildModernTextField(
                  cs,
                  controller: _nameController,
                  label: 'Nombre',
                  icon: Icons.person_outline_rounded,
                  onSubmitted: (_) => _saveProfile(),
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  cs,
                  controller: TextEditingController(text: _nameController.text.isNotEmpty ? 'usuario@ejemplo.com' : ''),
                  label: 'Correo electrónico',
                  icon: Icons.email_outlined,
                  readOnly: true,
                  filled: true,
                ),
                const SizedBox(height: 24),
                _buildPrimaryButton(
                  cs,
                  label: 'Guardar Perfil',
                  onPressed: _savingProfile ? null : _saveProfile,
                  loading: _savingProfile,
                  icon: Icons.save_rounded,
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildPasswordSection(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.lock_rounded, color: cs.secondary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text('Seguridad', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildModernTextField(
                  cs,
                  controller: _currentPasswordController,
                  label: 'Contraseña actual',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  cs,
                  controller: _newPasswordController,
                  label: 'Nueva contraseña',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  cs,
                  controller: _confirmPasswordController,
                  label: 'Confirmar nueva contraseña',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                _buildSecondaryButton(
                  cs,
                  label: 'Cambiar Contraseña',
                  onPressed: _savingPassword ? null : _changePassword,
                  loading: _savingPassword,
                  icon: Icons.key_rounded,
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildPreferencesSection(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.tertiaryContainer.withValues(alpha: 0.2),
                  cs.surface,
                ],
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.tertiary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.settings_rounded, color: cs.tertiary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text('Preferencias', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildModernTextField(
                  cs,
                  controller: _currencyController,
                  label: 'Moneda (ej. PEN, USD)',
                  icon: Icons.attach_money_rounded,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  cs,
                  controller: _budgetController,
                  label: 'Límite de presupuesto mensual',
                  icon: Icons.account_balance_wallet_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                _buildPrimaryButton(
                  cs,
                  label: 'Guardar Preferencias',
                  onPressed: _savingProfile ? null : _saveProfile,
                  loading: _savingProfile,
                  icon: Icons.save_rounded,
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildSavingsGoalsSection(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.tertiary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.savings_rounded, color: cs.tertiary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Metas de Ahorro',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildIconButton(
                  cs,
                  icon: Icons.add_rounded,
                  label: 'Nueva Meta',
                  onPressed: _showGoalBottomSheet,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_goals.isEmpty)
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        cs.primaryContainer.withValues(alpha: 0.3),
                        cs.surface,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.savings_outlined, size: 48, color: cs.onPrimaryContainer),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No tienes metas de ahorro',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea tu primera meta para empezar a ahorrar de forma inteligente',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      _buildPrimaryButton(
                        cs,
                        label: 'Crear mi primera meta',
                        onPressed: _showGoalBottomSheet,
                        icon: Icons.add_rounded,
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: List.generate(_goals.length, (index) {
                  final goal = _goals[index];
                  final color = _getGoalColor(index);
                  return _buildGoalCard(cs, goal, color, index);
                }),
              ),
          ],
        ),
    );
  }

  Widget _buildGoalCard(ColorScheme cs, SavingsGoalModel goal, Color accentColor, int index) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1.5),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.flag_rounded, color: Colors.white, size: 24),
          ),
          title: Text(
            goal.title,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: cs.onSurface),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: goal.progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(accentColor),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'S/ ${goal.currentAmount.toStringAsFixed(0)} / S/ ${goal.targetAmount.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${(goal.progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: Colors.red.withValues(alpha: 0.8)),
            onPressed: () => _deleteGoal(goal.id),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

  Color _getGoalColor(int index) {
    const colors = [
      Color(0xFF6366F1), // Indigo
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
      Color(0xFFEF4444), // Red
      Color(0xFF06B6D4), // Cyan
      Color(0xFF8B5CF6), // Violet
    ];
    return colors[index % colors.length];
  }

  void _showGoalBottomSheet() {
    _goalTitleController.clear();
    _goalTargetController.clear();
    _goalCurrentController.clear();
    _goalDeadline = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final sheetCs = Theme.of(sheetContext).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: sheetCs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48, height: 5,
                    decoration: BoxDecoration(
                      color: sheetCs.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: sheetCs.tertiary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.flag_rounded, color: sheetCs.tertiary, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Text('Nueva Meta de Ahorro', style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildModernTextField(
                  sheetCs,
                  controller: _goalTitleController,
                  label: 'Título (ej. Vacaciones, Emergencia)',
                  icon: Icons.title_rounded,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  sheetCs,
                  controller: _goalTargetController,
                  label: 'Monto objetivo',
                  icon: Icons.attach_money_rounded,
                  prefixText: 'S/ ',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  sheetCs,
                  controller: _goalCurrentController,
                  label: 'Monto actual (opcional)',
                  icon: Icons.account_balance_wallet_rounded,
                  prefixText: 'S/ ',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: sheetCs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.calendar_today_rounded, color: sheetCs.primary, size: 22),
                  ),
                  title: Text('Fecha límite', style: TextStyle(color: sheetCs.onSurfaceVariant)),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy').format(_goalDeadline),
                    style: TextStyle(fontWeight: FontWeight.w600, color: sheetCs.onSurface),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: sheetCs.onSurfaceVariant),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: sheetContext,
                      initialDate: _goalDeadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: sheetCs,
                          dialogTheme: DialogThemeData(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _goalDeadline = picked);
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  },
                ),
                const SizedBox(height: 24),
                _buildPrimaryButton(
                  sheetCs,
                  label: 'Crear Meta',
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _createGoal();
                  },
                  icon: Icons.add_rounded,
                ),
                const SizedBox(height: 20),
],
        ),
      ));
  },
    );
  }

  Widget _buildModernTextField(
    ColorScheme cs, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? prefixText,
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
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: cs.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        prefixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: cs.onSurface),
        prefixIcon: Icon(icon, color: cs.onSurfaceVariant, size: 22),
        filled: filled,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primary, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.error),
        ),
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  Widget _buildPrimaryButton(
    ColorScheme cs, {
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          shadowColor: cs.primary.withValues(alpha: 0.4),
        ),
        child: loading
            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 22), const SizedBox(width: 10)],
                  Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }

  Widget _buildSecondaryButton(
    ColorScheme cs, {
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: cs.secondary,
          foregroundColor: cs.onSecondary,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          shadowColor: cs.secondary.withValues(alpha: 0.4),
        ),
        child: loading
            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 22), const SizedBox(width: 10)],
                  Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
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
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: cs.primary),
      label: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: cs.primaryContainer.withValues(alpha: 0.3),
        foregroundColor: cs.primary,
      ),
    );
  }
}