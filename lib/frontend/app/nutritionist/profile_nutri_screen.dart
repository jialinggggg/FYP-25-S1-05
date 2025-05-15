import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../backend/controllers/fetch_nutri_profile_controller.dart';
import 'edit_profile_nutri_screen.dart';

class NutritionistProfileScreen extends StatefulWidget {
  const NutritionistProfileScreen({super.key});

  @override
  State<NutritionistProfileScreen> createState() => _NutritionistProfileScreenState();
}

class _NutritionistProfileScreenState extends State<NutritionistProfileScreen> {
  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context
            .read<FetchNutritionistProfileInfoController>()
            .loadProfileData(userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.green,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<FetchNutritionistProfileInfoController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            );
          }

          final account = controller.account;
          final profile = controller.nutritionistProfile;
          if (account == null || profile == null) {
            return const Center(child: Text('Profile data not found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _buildSection(
                  context,
                  title: 'Account Details',
                  icon: Icons.account_circle_outlined,
                  iconColor: Colors.green,
                  children: [
                    const SizedBox(height: 12),
                    _buildInfoRow('Email', account.email),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSection(
                  context,
                  title: 'Nutritionist Information',
                  icon: Icons.badge_outlined,
                  iconColor: Colors.green,
                  onEdit: () => _navigateToEditProfile(context, controller),
                  children: [
                    const SizedBox(height: 12),
                    _buildInfoRow('Full Name', profile.fullName),
                    _buildDivider(),
                    _buildInfoRow(
                  'Organization',
                  (profile.organization != null && profile.organization!.isNotEmpty)
                      ? profile.organization!
                      : 'Not specified',
                ),
                    _buildDivider(),
                    _buildInfoRow('License Number', profile.licenseNumber),
                    _buildDivider(),
                    _buildInfoRow('Issuing Body', profile.issuingBody),
                    _buildDivider(),
                    _buildInfoRow(
                      'Issuance Date',
                      _formatDate(profile.issuanceDate),
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      'Expiration Date',
                      _formatDate(profile.expirationDate),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Uploaded Documents',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    _buildDocList(profile.licenseScanUrls),
                  ],
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleLogout(controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Log Out', style: TextStyle(color: colors.onPrimary)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  void _navigateToEditProfile(BuildContext context, FetchNutritionistProfileInfoController c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditNutritionistProfileScreen(onProfileUpdated: () => _refreshProfile(c)),
      ),
    );
  }

  void _refreshProfile(FetchNutritionistProfileInfoController c) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) c.loadProfileData(userId);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    Color? iconColor,
    VoidCallback? onEdit,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 22, color: iconColor ?? theme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (onEdit != null)
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Edit'),
              ),
          ]),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontSize: 15, color: Colors.black54)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }

  Widget _buildDivider() => Divider(height: 1, thickness: 0.5, color: Colors.grey[300]);

  Widget _buildDocList(List<String> urls) {
    if (urls.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Text(
          '• Not specified',
          style: TextStyle(color: Colors.grey[600], fontSize: 15),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: urls
          .map(
            (u) => Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4),
              child: Text(
                '• ${u.split('/').last}',
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
          )
          .toList(),
    );
  }

  void _handleLogout(FetchNutritionistProfileInfoController controller) async {
    try {
      await controller.logout();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      if (mounted) 
        {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')), 
        );
        }
    }
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 1,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      onTap: (i) {
        if (i == 1) return;
        Navigator.pushReplacementNamed(
          context,
          ['/biz_recipes', '/nutri_profile'][i],
        );
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Recipes'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
