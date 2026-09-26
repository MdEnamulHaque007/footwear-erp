/// ============================================================================
/// ফাইল: lib/presentation/screens/settings/business_settings_screen.dart
/// স্তর: Presentation Screen | মডিউল: Settings
/// উদ্দেশ্য: Settings মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: BusinessSettingsScreen, _BusinessSettingsScreenState, _AdminOnlyMessage
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/color_palette.dart';
import '../../../domain/entities/settings/business_settings_entity.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/settings/settings_event.dart';
import '../../blocs/settings/settings_state.dart';
import '../../widgets/app_drawer.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _logoController = TextEditingController();
  String _currency = 'USD';
  String _unit = 'pair';
  BusinessSettingsEntity? _settings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SettingsBloc>().add(const LoadBusinessSettings());
      }
    });
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: const AppDrawer(),
    appBar: AppBar(
      leadingWidth: 96,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/settings'),
          ),
          Builder(
            builder: (drawerContext) => IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(drawerContext).openDrawer(),
            ),
          ),
        ],
      ),
      title: const Text('Company Info'),
    ),
    body: BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isAdmin = authState is Authenticated && authState.user.isAdmin;
        if (!isAdmin) return const _AdminOnlyMessage();
        return BlocConsumer<SettingsBloc, SettingsState>(
          listener: (context, state) {
            if (state is SettingsSaved || state is SettingsError) {
              final message = state is SettingsSaved
                  ? state.message
                  : (state as SettingsError).message;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }
          },
          builder: (context, state) {
            if (state is SettingsLoading || state is SettingsInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SettingsError) {
              return Center(
                child: FilledButton.icon(
                  onPressed: () => context.read<SettingsBloc>().add(
                    const LoadBusinessSettings(),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              );
            }
            if (state is! BusinessSettingsLoaded) {
              return const SizedBox.shrink();
            }
            _hydrate(state.entity);
            return _form(state.entity, isSaving: false);
          },
        );
      },
    ),
  );

  void _hydrate(BusinessSettingsEntity entity) {
    if (identical(_settings, entity)) return;
    _settings = entity;
    _companyNameController.text = entity.companyName;
    _addressController.text = entity.companyAddress;
    _phoneController.text = entity.companyPhone;
    _emailController.text = entity.companyEmail;
    _logoController.text = entity.companyLogo ?? '';
    _currency = const ['USD', 'BDT', 'EUR', 'GBP'].contains(entity.currency)
        ? entity.currency
        : 'USD';
    _unit = const ['pair', 'piece', 'dozen', 'carton'].contains(entity.unit)
        ? entity.unit
        : 'pair';
  }

  Widget _form(
    BusinessSettingsEntity entity, {
    required bool isSaving,
  }) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
    children: [
      Text(
        'BUSINESS PROFILE',
        style: const TextStyle(
          color: ColorPalette.muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 8),
      Form(
        key: _formKey,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(
                  controller: _companyNameController,
                  label: 'Company name',
                  icon: Icons.business_outlined,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Company name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _addressController,
                  label: 'Company address',
                  icon: Icons.location_on_outlined,
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _phoneController,
                  label: 'Phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _emailController,
                  label: 'Company email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty || email.contains('@')) return null;
                    return 'Enter a valid email address';
                  },
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _logoController,
                  label: 'Logo URL (optional)',
                  icon: Icons.image_outlined,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  items: const ['USD', 'BDT', 'EUR', 'GBP']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _currency = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _unit,
                  decoration: const InputDecoration(
                    labelText: 'Default unit',
                    prefixIcon: Icon(Icons.straighten_outlined),
                  ),
                  items: const ['pair', 'piece', 'dozen', 'carton']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _unit = value);
                  },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: isSaving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save company info'),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int minLines = 1,
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    validator: validator,
    minLines: minLines,
    maxLines: maxLines,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
  );

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false) || _settings == null) {
      return;
    }
    final logo = _logoController.text.trim();
    context.read<SettingsBloc>().add(
      SaveBusinessSettings(
        _settings!.copyWith(
          companyName: _companyNameController.text.trim(),
          companyAddress: _addressController.text.trim(),
          companyPhone: _phoneController.text.trim(),
          companyEmail: _emailController.text.trim(),
          companyLogo: logo.isEmpty ? null : logo,
          currency: _currency,
          unit: _unit,
        ),
      ),
    );
  }
}

class _AdminOnlyMessage extends StatelessWidget {
  const _AdminOnlyMessage();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Only administrators can edit company information.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}
