import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> account; // Change to Map<String, dynamic>
  final Function(String, Map<String, String>, bool) onUpdate;
  final Function(String, bool) onDelete;
  final bool isBusiness; // Determines if it's a Business Partner

  const ProfilePage({
    super.key,
    required this.account,
    required this.onUpdate,
    required this.onDelete,
    required this.isBusiness,
  });

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  bool hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account["name"]);
    _emailController = TextEditingController(text: widget.account["email"]);
    _locationController = TextEditingController(text: widget.account["location"]);

    _nameController.addListener(() => _checkChanges());
    _emailController.addListener(() => _checkChanges());
    _locationController.addListener(() => _checkChanges());
  }

  void _checkChanges() {
    setState(() {
      hasChanges = _nameController.text != widget.account["name"] ||
          _emailController.text != widget.account["email"] ||
          _locationController.text != widget.account["location"];
    });
  }

  void _saveChanges() {
    if (hasChanges) {
      Map<String, String> updatedData = {
        "name": _nameController.text,
        "email": _emailController.text,
        "location": _locationController.text,
      };

      widget.onUpdate(widget.account["uid"]!, updatedData, widget.isBusiness);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully"),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context, {"updatedData": updatedData, "uid": widget.account["uid"]});
    }
  }

  void _deleteAccount() {
    widget.onDelete(widget.account["uid"]!, widget.isBusiness);

    Navigator.pop(context, {"deleted": true, "uid": widget.account["uid"]});
  }

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isBusiness ? "Business Profile" : "User Profile",
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElevatedButton.icon(
              onPressed: _deleteAccount,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text(
                "Delete Account",
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // ✅ Red button
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: isWideScreen
            ? EdgeInsets.symmetric(horizontal: 100, vertical: 20)
            : EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// **Profile Image & Profile Details (2 Columns)**
            Row(
              children: [
                /// **Profile Image**
                CircleAvatar(
                  radius: 150,
                  backgroundImage: AssetImage(widget.account["image"]!),
                ),
                const SizedBox(width: 50),

                /// **Profile Details Column**
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReadOnlyField("UID", widget.account["uid"]!),
                      _buildEditableField(widget.isBusiness ? "Business Name" : "Name", _nameController),
                      _buildEditableField("Email", _emailController),
                      _buildEditableField("Location", _locationController),
                      _buildReadOnlyField("Joined Date", widget.account["date"]!),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// **Save Button**
            Center(
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  minimumSize: const Size(200, 45), // ✅ Smaller button with padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Save Changes", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        readOnly: true,
        initialValue: value,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}