import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../backend/controllers/fetch_biz_profile_controller.dart';
import 'edit_biz_contact_screen.dart';
import 'edit_biz_profile_screen.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  @override
  void initState() {
    super.initState();
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<FetchBusinessProfileInfoController>().loadProfileData(uid);
        }
      });
    }
  }

  void _refreshProfile(FetchBusinessProfileInfoController c) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) c.loadProfileData(uid);
  }

  void _navigateToEditProfile(BuildContext context, FetchBusinessProfileInfoController c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditBizProfileScreen(
          onUpdated: () => _refreshProfile(c),
        ),
      ),
    );
  }

  void _navigateToEditContact(BuildContext context, FetchBusinessProfileInfoController c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditBizContactScreen(
          onUpdated: () => _refreshProfile(c),
        ),
      ),
    );
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
          style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<FetchBusinessProfileInfoController>(
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
          final profile = controller.businessProfile;
          if (account == null || profile == null) {
            return Center(
              child: Text(
                'Could not load profile data.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // — Account Details (no Edit) —
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

                // — Business Profile —
                _buildSection(
                  context,
                  title: 'Business Profile',
                  icon: Icons.business_outlined,
                  iconColor: Colors.green,
                  onEdit: () => _navigateToEditProfile(context, controller),
                  children: [
                    const SizedBox(height: 12),
                    _buildInfoRow('Business Name', profile.businessName),
                    _buildDivider(),
                    _buildInfoRow('Registration No.', profile.registrationNo),
                    _buildDivider(),
                    _buildInfoRow('Country', profile.country),
                    _buildDivider(),
                    _buildInfoRow('Address', profile.address),
                    _buildDivider(),
                    _buildInfoRow(
                      'Description',
                      profile.description.isNotEmpty ? profile.description : 'Not specified',
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      'Website',
                      profile.website.isNotEmpty ? profile.website : 'Not specified',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Registration Documents',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildDocList(profile.registrationDocUrls),
                  ],
                ),
                const SizedBox(height: 20),

                // — Contact Person —
                _buildSection(
                  context,
                  title: 'Contact Person',
                  icon: Icons.contact_mail_outlined,
                  iconColor: Colors.green,
                  onEdit: () => _navigateToEditContact(context, controller),
                  children: [
                    const SizedBox(height: 12),
                    _buildInfoRow('Name', profile.contactName),
                    _buildDivider(),
                    _buildInfoRow('Role', profile.contactRole),
                    _buildDivider(),
                    _buildInfoRow('Email', profile.contactEmail),
                  ],
                ),
                const SizedBox(height: 30),

                // — Logout —
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: ElevatedButton(
                    onPressed: () async {
                      await controller.logout();
                      if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Log Out', style: TextStyle(color: colors.onPrimary)),
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
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: iconColor ?? theme.primaryColor),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (onEdit != null)
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                  child: const Text('Edit'),
                ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 15, color: Colors.black54))),
          Expanded(flex: 3, child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, thickness: 0.5, color: Colors.grey[300]);

  Widget _buildDocList(List<String> urls) {
    if (urls.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Text('• Not specified', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: urls
          .map((u) => Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 4),
                child: Text('• ${u.split('/').last}', style: const TextStyle(fontSize: 15, height: 1.4)),
              ))
          .toList(),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 3,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      onTap: (i) {
        if (i == 3) return;
        Navigator.pushReplacementNamed(context, ['/biz_recipes', '/biz_products', '/biz_orders', '/biz_profile'][i]);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Recipes'),
        BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Products'),
        BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}