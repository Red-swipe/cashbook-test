import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/colored_context.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/export_service.dart';
import '../../services/currency_service.dart';
import 'widgets/settings_tile.dart';
import 'widgets/settings_section.dart';
import 'categories_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final tp = context.read<TransactionProvider>();
    final theme = context.watch<ThemeProvider>();
    final symbol = sp.currencySymbol;
    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.background,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: context.text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20),
        children: [
          SizedBox(height: 8),
          SettingsSection(
            title: 'Account',
            children: [
              SettingsTile(
                leading: Icons.person,
                title: 'Username',
                subtitle: sp.username,
                onTap: () => _editUsername(context, sp),
              ),
              SettingsTile(
                leading: Icons.calendar_today,
                title: 'Install Date',
                subtitle: 'N/A',
              ),
            ],
          ),
          SizedBox(height: 12),
          SettingsSection(
            title: 'Currency',
            children: [
              SettingsTile(
                leading: Icons.monetization_on,
                title: 'Currency',
                subtitle: '${sp.currency} ($symbol)',
                onTap: () => _pickCurrency(context, sp),
              ),
            ],
          ),
          SizedBox(height: 12),
          SettingsSection(
            title: 'Appearance',
            children: [
              SettingsTile(
                leading: Icons.dark_mode,
                title: 'Dark Mode',
                trailing: Switch(
                  value: theme.isDark,
                  onChanged: (_) => theme.toggleTheme(),
                  activeThumbColor: context.text,
                  inactiveThumbColor: context.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SettingsSection(
            title: 'Categories',
            children: [
              SettingsTile(
                leading: Icons.category,
                title: 'Manage Categories',
                subtitle: '${sp.categories.length} categories',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: sp,
                      child: CategoriesScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SettingsSection(
            title: 'Data Management',
            children: [
              SettingsTile(
                leading: Icons.file_download,
                title: 'Export CSV',
                onTap: () => _exportCsv(context, sp),
              ),
              SettingsTile(
                leading: Icons.picture_as_pdf,
                title: 'Export PDF',
                onTap: () => _exportPdf(context, sp),
              ),
              SettingsTile(
                leading: Icons.refresh,
                title: 'Refresh Rates',
                onTap: () => _refreshRates(context),
              ),
              SettingsTile(
                leading: Icons.delete_forever,
                title: 'Clear All Data',
                destructive: true,
                onTap: () => _clearData(context, tp),
              ),
            ],
          ),
          SizedBox(height: 12),
          SettingsSection(
            title: 'About',
            children: [
              SettingsTile(
                leading: Icons.info_outline,
                title: 'Version',
                subtitle: '1.0.0',
              ),
            ],
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  void _editUsername(BuildContext context, SettingsProvider sp) {
    final controller = TextEditingController(text: sp.username);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        title: Text('Edit Username',
            style: TextStyle(color: context.text)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: context.text),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: context.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.textSecondary),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.text),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: context.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await sp.setUsername(controller.text.trim());
                // ignore: use_build_context_synchronously
                Navigator.pop(ctx);
              } catch (e) {
                debugPrint('setUsername error: $e');
              }
            },
            child: Text('Save',
                style: TextStyle(color: context.text)),
          ),
        ],
      ),
    );
  }

  void _pickCurrency(BuildContext rootContext, SettingsProvider sp) {
    showDialog(
      context: rootContext,
      builder: (ctx) => AlertDialog(
        backgroundColor: rootContext.surface,
        title: Text('Select Currency',
            style: TextStyle(color: rootContext.text)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: SettingsProvider.currencies.length,
            itemBuilder: (_, index) {
              final c = SettingsProvider.currencies[index];
              final isSelected = c['code'] == sp.currency;
              return ListTile(
                dense: true,
                selected: isSelected,
                selectedTileColor: rootContext.text.withValues(alpha: 0.1),
                title: Text(
                  '${c['code']} - ${c['name']} (${c['symbol']})',
                  style: TextStyle(
                    color: rootContext.text,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                subtitle: Text(
                  c['country']!,
                  style: TextStyle(color: rootContext.textSecondary),
                ),
                onTap: () {
                  final code = c['code']!;
                  Navigator.pop(ctx);
                  sp.setCurrency(code);
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(
                      content: Text('Currency changed to $code'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: rootContext.textSecondary)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, SettingsProvider sp) async {
    final tp = context.read<TransactionProvider>();
    if (tp.transactions.isEmpty) {
      _showSnack(context, 'No transactions to export');
      return;
    }
    await ExportService().exportToCsv(tp.transactions, sp);
  }

  Future<void> _exportPdf(BuildContext context, SettingsProvider sp) async {
    final tp = context.read<TransactionProvider>();
    if (tp.transactions.isEmpty) {
      _showSnack(context, 'No transactions to export');
      return;
    }
    await ExportService().exportToPdf(tp.transactions, sp);
  }

  Future<void> _refreshRates(BuildContext context) async {
    await CurrencyService().refreshRates();
    if (context.mounted) {
      _showSnack(context, 'Exchange rates refreshed');
    }
  }

  Future<void> _clearData(BuildContext context, TransactionProvider tp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        title: Text('Clear All Data',
            style: TextStyle(color: AppColors.expense)),
        content: Text(
          'This will delete ALL transactions. This action cannot be undone.',
          style: TextStyle(color: context.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: context.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete All',
                style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await tp.clearAll();
      if (context.mounted) {
        _showSnack(context, 'All data cleared');
      }
    }
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: context.surface,
      ),
    );
  }
}
