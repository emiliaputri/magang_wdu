import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/universal_image.dart';
import 'change_password_page.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().getUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Profile Settings',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
          ),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.primary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: authProvider.loading && user == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: () => authProvider.getUser(),
              color: AppTheme.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserHeader(user),
                    const SizedBox(height: 32),
                    
                    _buildSectionHeader('Profile Information', 'Update your account\'s profile information and email address.'),
                    _buildProfileInfoCard(user),
                    const SizedBox(height: 24),

                    _buildSectionHeader('Update Password', 'Ensure your account is using a long, random password to stay secure.'),
                    _buildActionCard(
                      icon: Icons.lock_outline_rounded,
                      title: 'Change Password',
                      subtitle: 'Update your login credentials',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage())),
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader('Two-Factor Authentication', 'Add additional security to your account using two-factor authentication.'),
                    _build2FACard(user),
                    const SizedBox(height: 24),

                    _buildSectionHeader('Browser Sessions', 'Manage and log out your active sessions on other browsers and devices.'),
                    _buildActionCard(
                      icon: Icons.devices_rounded,
                      title: 'Active Sessions',
                      subtitle: 'View where you are currently logged in',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon')));
                      },
                    ),
                    const SizedBox(height: 40),
                    
                    _buildLogoutButton(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserHeader(Map<String, dynamic>? user) {
    String? photoUrl = user?['profile_photo_url'];
    final name = user?['name'] ?? 'User';
    final email = user?['email'] ?? '';

    // Fix for local environment: if Laravel returns 127.0.0.1, change it to localhost
    if (photoUrl != null && photoUrl.contains('127.0.0.1')) {
      photoUrl = photoUrl.replaceFirst('127.0.0.1', 'localhost');
    }

    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(alpha: 0.1),
              border: Border.all(color: AppTheme.primary, width: 2),
            ),
            child: photoUrl != null 
              ? UniversalImage(
                  imageUrl: photoUrl,
                  width: 100,
                  height: 100,
                  borderRadius: 50,
                  fit: BoxFit.cover,
                  errorWidget: const Icon(Icons.person_rounded, size: 50, color: AppTheme.primary),
                )
              : const Icon(Icons.person_rounded, size: 50, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          Text(
            email,
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.outline,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoCard(Map<String, dynamic>? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.person_outline_rounded, 'Name', user?['name'] ?? '-'),
          const Divider(height: 32, indent: 40),
          _buildInfoRow(Icons.email_outlined, 'Email', user?['email'] ?? '-'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Save Information', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.outline, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurface, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _build2FACard(Map<String, dynamic>? user) {
    final bool isEnabled = user?['email_2fa_enabled'] == 1 || user?['email_2fa_enabled'] == true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isEnabled ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEnabled ? Icons.shield_rounded : Icons.shield_outlined,
                  color: isEnabled ? Colors.green : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEnabled ? '2FA is Enabled' : '2FA is Disabled',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isEnabled ? Colors.green : AppTheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isEnabled 
              ? 'You have enabled two-factor authentication. When you log in, you will be prompted for a secure, random token from your email.'
              : 'You have not enabled two-factor authentication. We recommend enabling it for better security.',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.outline, height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnabled ? Colors.red : AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(isEnabled ? 'Disable 2FA' : 'Enable 2FA', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.outline),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.outline),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () => _confirmLogout(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, size: 20),
            const SizedBox(width: 8),
            Text('Log Out', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to log out of the application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.outline)),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
