import 'package:flutter/material.dart';
import '../shared/login.dart';
import 'biz_partner_dashboard.dart';
import 'biz_products_screen.dart';
// import 'biz_orders_screen.dart'; // (Temporary Commented Out Until Created)

class BizProfileScreen extends StatefulWidget {
  const BizProfileScreen({super.key});

  @override
  BizProfileScreenState createState() => BizProfileScreenState();
}

class BizProfileScreenState extends State<BizProfileScreen> {
  /// Business Partner Information
  String name = "HealthyFood Pte Ltd";
  String email = "HealthyFood@HFPL.com";
  String registrationNumber = "1291839";
  String location = "Singapore";

  /// Controllers for Editable Fields
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _registrationController;
  late TextEditingController _locationController;

  bool _isEditing = false; // Toggle between View & Edit Mode
  int _selectedIndex = 3; // ✅ Profile tab index

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: name);
    _emailController = TextEditingController(text: email);
    _registrationController = TextEditingController(text: registrationNumber);
    _locationController = TextEditingController(text: location);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _registrationController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// **Save Profile & Switch Back to View Mode**
  void _saveProfile() {
    setState(() {
      name = _nameController.text;
      email = _emailController.text;
      registrationNumber = _registrationController.text;
      location = _locationController.text;
      _isEditing = false;
    });
  }

  /// **Delete Account Confirmation**
  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete this account? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Account deleted successfully.")),
              );
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// **Logout Function**
  void _logout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  /// **Bottom Navigation Logic**
  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });

      switch (index) {
        case 0:
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BizPartnerDashboard()));
          break;
        case 1:
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BizProductsScreen())); 
          break;
        case 2:
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BizOrdersScreen())); // ✅ Uncomment when BizOrdersScreen is ready
          break;
        case 3:
          break; // Stay on Profile Page
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// **App Bar**
      appBar: AppBar(
        title: const Text("Profile (Biz Partner)"),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            child: Text(
              _isEditing ? "Cancel" : "Edit",
              style: const TextStyle(fontSize: 16, color: Colors.green),
            ),
          ),
        ],
      ),

      /// **Body Content**
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /// **Profile Header**
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text("My Business Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            /// **Profile Fields**
            _isEditing
                ? _buildEditableField("Name", _nameController)
                : _buildProfileField("Name", name, isBold: true),

            _isEditing
                ? _buildEditableField("Email", _emailController)
                : _buildProfileField("Email", email),

            _isEditing
                ? _buildEditableField("Registration Number", _registrationController)
                : _buildProfileField("Registration Number", registrationNumber),

            _isEditing
                ? _buildEditableField("Location", _locationController)
                : _buildProfileField("Location", location),

            const SizedBox(height: 20),

            /// **Save Button (Only in Edit Mode)**
            if (_isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Save", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),

            /// **Delete Account Button**
            TextButton(
              onPressed: _showDeleteAccountConfirmation,
              child: const Text("Delete Account", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 10),

            /// **Logout Button**
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Logout", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),

      /// ✅ **Bottom Navigation Bar (Updated for Business Partner)**
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Recipes"),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: "Products"),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  /// **Reusable Profile Field (View Mode)**
  Widget _buildProfileField(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 16, color: Colors.black)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// **Reusable Input Field (Edit Mode)**
  Widget _buildEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}