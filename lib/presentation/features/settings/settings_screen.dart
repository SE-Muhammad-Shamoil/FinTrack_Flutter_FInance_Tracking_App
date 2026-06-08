import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finguard_ai/presentation/providers/app_providers.dart';
import 'package:finguard_ai/core/theme/app_theme.dart';
import 'package:finguard_ai/presentation/features/auth/biometric_interceptor.dart';
import 'package:finguard_ai/services/export_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBiometricEnabled = ref.watch(biometricLockEnabledProvider);
    final activeProfileId = ref.watch(activeProfileIdProvider);
    final currentCurrency = ref.watch(currencySymbolProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkModeEnabled = themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && isDark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text('Profiles', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          profilesAsync.when(
            data: (profiles) {
              return Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isDark ? AppTheme.neumorphicShadowDark : AppTheme.neumorphicShadowLight,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                    for (int i = 0; i < profiles.length; i++) ...[
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        tileColor: profiles[i].id == activeProfileId ? theme.primaryColor.withValues(alpha: 0.1) : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: profiles[i].id == activeProfileId ? BorderSide(color: theme.primaryColor.withValues(alpha: 0.5)) : BorderSide.none,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(int.parse(profiles[i].color.replaceFirst('#', '0xFF'))).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person_rounded, color: Color(int.parse(profiles[i].color.replaceFirst('#', '0xFF')))),
                        ),
                        title: Text(profiles[i].name, style: TextStyle(fontWeight: profiles[i].id == activeProfileId ? FontWeight.bold : FontWeight.w600, fontSize: 16, color: profiles[i].id == activeProfileId ? theme.primaryColor : null)),
                        trailing: profiles.length > 1 ? IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _deleteProfile(context, ref, profiles[i]),
                        ) : null,
                        onTap: () {
                          ref.read(activeProfileIdProvider.notifier).state = profiles[i].id ?? 1;
                        },
                      ),
                      if (i < profiles.length - 1)
                        Divider(height: 1, indent: 24, endIndent: 24, color: Colors.grey.withOpacity(0.2)),
                    ],
                    Divider(height: 1, indent: 24, endIndent: 24, color: Colors.grey.withOpacity(0.2)),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add_rounded, color: theme.primaryColor),
                      ),
                      title: Text('Create New Profile', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w600)),
                      onTap: () {
                        _showCreateProfileDialog(context, ref, isDark, theme);
                      },
                    ),
                  ],
                ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 40),
          Text('Preferences', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: isDark ? AppTheme.neumorphicShadowDark : AppTheme.neumorphicShadowLight,
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [

                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  title: const Text('Biometric App Lock', style: TextStyle(fontWeight: FontWeight.w500)),
                  value: isBiometricEnabled,
                  activeColor: theme.primaryColor,
                  onChanged: (val) {
                    ref.read(biometricLockEnabledProvider.notifier).state = val;
                  },
                ),
                Divider(height: 1, indent: 24, endIndent: 24, color: Colors.grey.withValues(alpha: 0.2)),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w500)),
                  value: isDarkModeEnabled,
                  activeColor: theme.primaryColor,
                  onChanged: (val) {
                    ref.read(themeModeProvider.notifier).state = val ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
                Divider(height: 1, indent: 24, endIndent: 24, color: Colors.grey.withValues(alpha: 0.2)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  title: const Text('Currency Symbol', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currentCurrency,
                      items: const [
                        DropdownMenuItem(value: '\$', child: Text('\$ (USD)')),
                        DropdownMenuItem(value: '€', child: Text('€ (EUR)')),
                        DropdownMenuItem(value: '£', child: Text('£ (GBP)')),
                        DropdownMenuItem(value: '₹', child: Text('₹ (INR)')),
                        DropdownMenuItem(value: 'Rs ', child: Text('Rs (PKR/INR)')),
                        DropdownMenuItem(value: '¥', child: Text('¥ (JPY/CNY)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(currencySymbolProvider.notifier).state = val;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
          const SizedBox(height: 40),
          Text('Data Portability', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: isDark ? AppTheme.neumorphicShadowDark : AppTheme.neumorphicShadowLight,
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.download_rounded, color: Colors.blue),
                  ),
                  title: const Text('Export to CSV', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final profileId = ref.read(activeProfileIdProvider);
                    await ExportService().exportTransactionsToCsv(profileId);
                  },
                ),
                Divider(height: 1, indent: 24, endIndent: 24, color: Colors.grey.withOpacity(0.2)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.upload_rounded, color: Colors.orange),
                  ),
                  title: const Text('Import Data', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import coming soon!')));
                  },
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteProfile(BuildContext context, WidgetRef ref, dynamic profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Profile?'),
        content: Text('Are you sure you want to delete ${profile.name}? This will remove all associated transactions, budgets, and data permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final db = await ref.read(databaseHelperProvider).database;
              await db.delete('profiles', where: 'id = ?', whereArgs: [profile.id]);
              
              // If deleted profile was active, switch to another profile
              final currentActiveId = ref.read(activeProfileIdProvider);
              if (currentActiveId == profile.id) {
                final remainingProfiles = await db.query('profiles', limit: 1);
                if (remainingProfiles.isNotEmpty) {
                  ref.read(activeProfileIdProvider.notifier).state = remainingProfiles.first['id'] as int;
                }
              }
              
              ref.invalidate(profilesProvider);
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showCreateProfileDialog(BuildContext context, WidgetRef ref, bool isDark, ThemeData theme) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('New Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'e.g. Business, Travel',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: theme.scaffoldBackgroundColor,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                if (context.mounted) Navigator.pop(context);
                final db = await ref.read(databaseHelperProvider).database;
                await db.insert('profiles', {
                  'name': controller.text,
                  'icon': 'person',
                  'color': '#E91E63',
                  'is_active': 0,
                });
                ref.invalidate(profilesProvider);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
