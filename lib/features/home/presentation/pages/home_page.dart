import 'package:flutter/material.dart';

import 'package:scandesk/core/config/app_settings.dart';
import 'package:scandesk/core/l10n/generated/app_localizations.dart';
import 'package:scandesk/core/theme/app_colors.dart';
import 'package:scandesk/core/widgets/empty_view.dart';
import 'package:scandesk/core/widgets/error_view.dart';
import 'package:scandesk/core/widgets/loading_view.dart';
import 'package:scandesk/core/widgets/primary_button.dart';
import '../widgets/supabase_status_card.dart';

/// Sprint 0 home: shows the foundation working (Supabase connection,
/// theme, Arabic/English, shared widgets).
///
/// TODO(S1): replace with role-based homes (employee / technician / manager).
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _buttonLoading = false;

  Future<void> _demoButton() async {
    setState(() => _buttonLoading = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _buttonLoading = false);
  }

  void _toggleLanguage() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    AppSettings.locale.value = Locale(isArabic ? 'en' : 'ar');
  }

  void _toggleTheme() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    AppSettings.themeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.changeLanguage,
            onPressed: _toggleLanguage,
            icon: const Icon(Icons.translate),
          ),
          IconButton(
            tooltip: l10n.changeTheme,
            onPressed: _toggleTheme,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.sprint0Title, style: textTheme.headlineSmall),
          Text(l10n.tagline, style: textTheme.bodyMedium),
          const SizedBox(height: 16),
          const SupabaseStatusCard(),
          const SizedBox(height: 24),
          Text(l10n.statusColors, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(l10n.statusNew, AppColors.statusNew),
              _StatusChip(l10n.statusAssigned, AppColors.statusAssigned),
              _StatusChip(l10n.statusInProgress, AppColors.statusInProgress),
              _StatusChip(l10n.statusResolved, AppColors.statusResolved),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.sharedWidgets, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          PrimaryButton(
            label: l10n.tapMe,
            icon: Icons.touch_app,
            isLoading: _buttonLoading,
            onPressed: _demoButton,
          ),
          const SizedBox(height: 12),
          const _DemoBox(child: LoadingView()),
          const _DemoBox(child: EmptyView()),
          _DemoBox(child: ErrorView(onRetry: () {})),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}

class _DemoBox extends StatelessWidget {
  const _DemoBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SizedBox(height: 220, child: child),
    );
  }
}
