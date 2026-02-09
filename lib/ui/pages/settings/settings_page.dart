import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../widgets/tab_header.dart';
import '../../atoms/atoms.dart';
import '../../../data/providers.dart';
import '../../../data/providers/auth_providers.dart';
import '../../../data/models/profile_models.dart';
import 'sub_pages/account_management_page.dart';
import 'sub_pages/privacy_policy_page.dart';
import 'sub_pages/terms_of_service_page.dart';
import 'sub_pages/app_info_page.dart';
import '../../../data/services/analytics_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AnalyticsService.logScreenView('settings_page');
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: WFColors.base,
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) => _buildSettingsContent(context, profile),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildSettingsContent(BuildContext context, UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(WFDims.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TabHeader(
            title: 'Beguile AI',
            subtitle: 'SETTINGS',
          ),
          const SizedBox(height: WFDims.spacingL),
          // Profile section
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: WFGradients.purpleGradient,
                    borderRadius: BorderRadius.circular(WFDims.radiusXLarge),
                    boxShadow: WFShadows.purpleGlow,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: WFColors.textPrimary,
                  ),
                ),
                const SizedBox(height: WFDims.spacingL),
                Text('SETTINGS', style: WFTextStyles.h1),
                const SizedBox(height: WFDims.spacingS),
                Text(
                  'Manage your Beguile AI experience',
                  style: WFTextStyles.bodyMedium
                      .copyWith(color: WFColors.textTertiary),
                ),
              ],
            ),
          ),

          const SizedBox(height: WFDims.spacingXXL),

          // Profile Section (Inline)
          _buildProfileSection(context, profile),

          const SizedBox(height: WFDims.spacingL),

          // Settings Options
          _buildSettingsOption(
            context,
            'Account Management',
            'Delete account, reset progress, manage data',
            Icons.account_circle,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AccountManagementPage()),
            ),
          ),

          const SizedBox(height: WFDims.spacingM),

          _buildSettingsOption(
            context,
            'Privacy Policy',
            'Read our privacy policy',
            Icons.privacy_tip,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyPage()),
            ),
          ),

          const SizedBox(height: WFDims.spacingM),

          _buildSettingsOption(
            context,
            'Terms of Service',
            'Read our terms of service',
            Icons.description,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const TermsOfServicePage()),
            ),
          ),

          const SizedBox(height: WFDims.spacingM),

          _buildSettingsOption(
            context,
            'App Information',
            'Version, about, contact',
            Icons.info,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AppInfoPage()),
            ),
          ),

          const SizedBox(height: WFDims.spacingM),

          // Sign Out Button
          _buildSignOutOption(context),

          const SizedBox(height: WFDims.spacingXXL),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, UserProfile profile) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(WFDims.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: WFColors.purple400, size: 24),
                const SizedBox(width: WFDims.spacingS),
                Text('Profile', style: WFTextStyles.h3),
              ],
            ),
            const SizedBox(height: WFDims.spacingL),
            _buildProfileTile('Display Name', profile.id, Icons.person),
            const SizedBox(height: WFDims.spacingM),
            _buildProfileTile('Total XP', '${profile.xpTotal}', Icons.star),
            const SizedBox(height: WFDims.spacingM),
            _buildProfileTile(
                'Account Level',
                'Level ${_calculateAccountLevel(profile.xpTotal)}',
                Icons.trending_up),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(WFDims.paddingM),
      decoration: BoxDecoration(
        color: WFColors.gray800.withOpacity(0.3),
        borderRadius: BorderRadius.circular(WFDims.radiusMedium),
        border: Border.all(color: WFColors.glassBorder.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: WFColors.purple400, size: 20),
          const SizedBox(width: WFDims.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: WFTextStyles.labelLarge),
                const SizedBox(height: 2),
                Text(value,
                    style: WFTextStyles.bodyMedium
                        .copyWith(color: WFColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WFDims.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(WFDims.paddingM),
        decoration: BoxDecoration(
          color: WFColors.gray800.withOpacity(0.3),
          borderRadius: BorderRadius.circular(WFDims.radiusMedium),
          border: Border.all(color: WFColors.glassBorder.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: WFColors.purple400, size: 20),
            const SizedBox(width: WFDims.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: WFTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: WFTextStyles.bodySmall
                          .copyWith(color: WFColors.textTertiary)),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: WFColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  int _calculateAccountLevel(int xp) {
    if (xp < 100) return 1;
    if (xp < 500) return 2;
    if (xp < 1000) return 3;
    if (xp < 2000) return 4;
    if (xp < 5000) return 5;
    return 6;
  }

  Widget _buildSignOutOption(BuildContext context) {
    return InkWell(
      onTap: () => _showSignOutDialog(context),
      borderRadius: BorderRadius.circular(WFDims.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(WFDims.paddingM),
        decoration: BoxDecoration(
          color: WFColors.gray800.withOpacity(0.3),
          borderRadius: BorderRadius.circular(WFDims.radiusMedium),
          border: Border.all(color: WFColors.glassBorder.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.logout, color: Colors.red, size: 20),
            const SizedBox(width: WFDims.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sign Out', style: WFTextStyles.labelLarge.copyWith(color: Colors.red)),
                  const SizedBox(height: 2),
                  Text('Sign out of your account',
                      style: WFTextStyles.bodySmall
                          .copyWith(color: WFColors.textTertiary)),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: WFColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: WFColors.gray800,
          title: Text(
            'Sign Out',
            style: WFTextStyles.h3.copyWith(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to sign out?',
            style: WFTextStyles.bodyMedium.copyWith(color: WFColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: WFTextStyles.bodyMedium.copyWith(color: WFColors.gray400),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _signOut(context);
              },
              child: Text(
                'Sign Out',
                style: WFTextStyles.bodyMedium.copyWith(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      final authService = ProviderScope.containerOf(context).read(authServiceProvider);
      await authService.signOut();
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }
}
