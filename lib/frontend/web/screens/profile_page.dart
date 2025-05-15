import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../backend/controller/accounts_controller.dart';

class ProfilePage extends StatefulWidget {
  final String uid;

  const ProfilePage({super.key, required this.uid});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final AccountsController _accountsController = AccountsController(Supabase.instance.client);

  Map<String, dynamic>? accountDetails;
  Map<String, dynamic>? profileDetails;
  Map<String, dynamic>? userGoals;
  Map<String, dynamic>? userMedicalInfo;
  String profileType = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      accountDetails = await _accountsController.fetchAccountDetails(widget.uid);
      profileType = await _accountsController.fetchProfileType(widget.uid);
      profileDetails = await _accountsController.fetchProfileByType(widget.uid, profileType);

      if (profileType == 'user_profiles') {
        userGoals = await _accountsController.fetchUserGoals(widget.uid);
        userMedicalInfo = await _accountsController.fetchUserMedicalInfo(widget.uid);
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching profile data: ${e.toString()}')),
        );
      }
    }
  }

  void _openEditDialog() {
    final Map<String, TextEditingController> controllers = {};

    // Populate controllers for name and email only
    if (profileDetails != null) {
      controllers["name"] = TextEditingController(text: profileDetails?["name"] ?? "N/A");
    }
    if (accountDetails != null) {
      controllers["email"] = TextEditingController(text: accountDetails?["email"] ?? "N/A");
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Edit Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Editable Fields
                  for (final entry in controllers.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: TextField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          labelText: _formatLabel(entry.key),
                          border: const OutlineInputBorder(),
                          errorText: entry.key == "email" && !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(entry.value.text)
                              ? "Please enter a valid email address"
                              : null,

                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),

                  // Save and Cancel Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            // Extract the updated values
                            Map<String, dynamic> updatedProfileDetails = {};
                            Map<String, dynamic> updatedAccountDetails = {};
                            Map<String, dynamic>? updatedUserGoals;
                            Map<String, dynamic>? updatedUserMedicalInfo;

                            // Separate profile and account data
                            controllers.forEach((key, controller) {
                              if (profileDetails?.containsKey(key) ?? false) {
                                updatedProfileDetails[key] = controller.text;
                              } else if (accountDetails?.containsKey(key) ?? false) {
                                updatedAccountDetails[key] = controller.text;
                              } else if (profileType == 'user_profiles') {
                                if (userGoals?.containsKey(key) ?? false) {
                                  updatedUserGoals ??= {};
                                  updatedUserGoals![key] = controller.text;
                                }
                                if (userMedicalInfo?.containsKey(key) ?? false) {
                                  updatedUserMedicalInfo ??= {};
                                  updatedUserMedicalInfo![key] = controller.text;
                                }
                              }
                            });

                            // Call the update method
                            await _accountsController.updateProfile(
                              widget.uid,
                              profileType,
                              updatedProfileDetails,
                              updatedAccountDetails,
                              updatedUserGoals,
                              updatedUserMedicalInfo,
                            );

                            // Update the local state
                            setState(() {
                              profileDetails?.addAll(updatedProfileDetails);
                              accountDetails?.addAll(updatedAccountDetails);
                              if (profileType == 'user_profiles') {
                                userGoals?.addAll(updatedUserGoals ?? {});
                                userMedicalInfo?.addAll(updatedUserMedicalInfo ?? {});
                              }
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Profile updated successfully")),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to update profile: $e")),
                            );
                          }
                        },
                        child: const Text("Save"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel"),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatLabel(String key) {
    // Capitalize each word and replace underscores with spaces
    return key
        .split('_')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final status = accountDetails?['status'] ?? 'Inactive';
    final name = _getDisplayName();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _getProfileTitle(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (status != "Unknown")
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == "active"
                      ? Colors.green
                      : status == "pending"
                      ? Colors.orange
                      : Colors.red,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        backgroundColor: Colors.green[700],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                if (profileType == "business_profiles")
                  TextButton(
                    onPressed: () => _openDocumentPreview(profileDetails?["registration_doc_urls"], "UEN Document"),
                    child: const Text("Open UEN Doc", style: TextStyle(color: Colors.blue)),
                  ),
                if (profileType == "nutritionist_profiles")
                  TextButton(
                    onPressed: () => _openDocumentPreview(profileDetails?["license_scan_urls"], "License"),
                    child: const Text("Open License", style: TextStyle(color: Colors.blue)),
                  ),
                /// Three Dots Menu
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.black54),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.edit, color: Colors.blue),
                              title: const Text("Edit Profile"),
                              onTap: () {
                                Navigator.pop(context); // Close the bottom sheet
                                _openEditDialog();
                              },
                            ),
                            const Divider(),
                            // Suspend Account Option (Active Accounts Only)
                            if (accountDetails?["status"] == "active")
                              ListTile(
                                leading: const Icon(Icons.block, color: Colors.red),
                                title: const Text("Suspend Account"),
                                onTap: () async {
                                  Navigator.pop(context);

                                  // Suspend the account
                                  await _accountsController.updateAccountStatus(widget.uid, "suspended");

                                  // Update local status
                                  setState(() {
                                    accountDetails?["status"] = "suspended";
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Account suspended successfully")),
                                  );
                                },
                              ),
                            // Revert Status Option (Active Accounts Only)
                            if (accountDetails?["status"] == "rejected")
                              ListTile(
                                leading: const Icon(Icons.block, color: Colors.red),
                                title: const Text("Revert Status"),
                                onTap: () async {
                                  Navigator.pop(context);

                                  // Suspend the account
                                  await _accountsController.updateAccountStatus(widget.uid, "pending");

                                  // Update local status
                                  setState(() {
                                    accountDetails?["status"] = "pending";
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Account status reverted successfully")),
                                  );
                                },
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Physical Details (Weight, Height, Gender) - Users Only
            if (profileType == "user_profiles")
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Gender Icon and Label
                  Row(
                    children: [
                      Icon(
                        profileDetails?["gender"]?.toString().toLowerCase() == "male"
                            ? Icons.male
                            : profileDetails?["gender"]?.toString().toLowerCase() == "female"
                            ? Icons.female
                            : Icons.person,
                        color: Colors.black54,
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${profileDetails?["gender"] ?? "N/A"}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),

                  const SizedBox(width: 15),

                  // Weight
                  Row(
                    children: [
                      const Icon(Icons.monitor_weight, color: Colors.black54, size: 20),
                      const SizedBox(width: 5),
                      Text('${profileDetails?["weight"] ?? "N/A"} kg', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),

                  const SizedBox(width: 15),

                  // Height
                  Row(
                    children: [
                      const Icon(Icons.height, color: Colors.black54, size: 20),
                      Text('${profileDetails?["height"] ?? "N/A"} cm', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            Text('Created on ${accountDetails?['created_at']?.split('T')[0] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const Divider(color: Colors.black26),
            const SizedBox(height: 20),

            /// Remaining Profile Details
            _buildProfileDetails(),

            const SizedBox(height: 30),

            /// Accept and Reject Buttons
            if (status == "pending")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 500),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: Row(
                    children: [
                      /// Accept Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _accountsController.updateAccountStatus(widget.uid, "active");
                            setState(() {
                              accountDetails?["status"] = "active";
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Account accepted successfully")),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.black26),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check_circle, color: Colors.white, size: 18),
                              SizedBox(width: 5),
                              Text(
                                "Accept",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      /// Reject Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _accountsController.updateAccountStatus(widget.uid, "rejected");
                            setState(() {
                              accountDetails?["status"] = "rejected";
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Account rejected successfully")),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide.none,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.cancel, color: Colors.white, size: 18),
                              SizedBox(width: 5),
                              Text(
                                "Reject",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getProfileTitle() {
    switch (profileType) {
      case 'user_profiles':
        return 'User Profile';
      case 'business_profiles':
        return 'Business Profile';
      case 'nutritionist_profiles':
        return 'Nutritionist Profile';
      default:
        return 'Profile';
    }
  }

  String _getDisplayName() {
    if (profileType == 'user_profiles') {
      return profileDetails?["name"] ?? "N/A";
    } else if (profileType == 'business_profiles') {
      return profileDetails?["name"] ?? "N/A";
    } else if (profileType == 'nutritionist_profiles') {
      return profileDetails?["full_name"] ?? "N/A";
    }
    return "N/A";
  }

  Widget _buildProfileDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email: ${accountDetails?["email"] ?? "N/A"}',
            style: const TextStyle(fontSize: 16)),

        // Additional User Details
        if (profileType == "user_profiles")
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Country: ${profileDetails?["country"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
              Text('Birth Date: ${profileDetails?["birth_date"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
              Text(
                'Pre-existing Conditions: ${(userMedicalInfo?["pre_existing"] is List && userMedicalInfo?["pre_existing"].isEmpty) ? "N/A" : (userMedicalInfo?["pre_existing"] as List).join(", ")}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Allergies: ${(userMedicalInfo?["allergies"] is List && userMedicalInfo?["allergies"].isEmpty) ? "N/A" : (userMedicalInfo?["allergies"] as List).join(", ")}',
                style: const TextStyle(fontSize: 16),
              ),
              Text('Daily Calories Goal: ${userGoals?["daily_calories"] ?? 0} kcal', style: const TextStyle(fontSize: 16)),
              Text('Protein Goal: ${userGoals?["protein"] ?? 0} g', style: const TextStyle(fontSize: 16)),
              Text('Carbs Goal: ${userGoals?["carbs"] ?? 0} g', style: const TextStyle(fontSize: 16)),
              Text('Fats Goal: ${userGoals?["fats"] ?? 0} g', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
            ],
          ),

        // Additional Business Details
        if (profileType == "business_profiles")
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contact Name: ${profileDetails?["contact_name"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
              Text('Contact Role: ${profileDetails?["contact_role"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
              Text('Contact Email: ${profileDetails?["contact_email"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
              Text('Country: ${profileDetails?["country"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
              Text('Address: ${profileDetails?["address"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
              Text('Registration No: ${profileDetails?["registration_no"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
              Text('Website: ${profileDetails?["website"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
              Text('Description: ${profileDetails?["description"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
            ],
          ),

        // Additional Nutritionist Details
        if (profileType == "nutritionist_profiles")
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Organisation: ${profileDetails?["organisation"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
              Text('License Number: ${profileDetails?["license_number"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
              Text('Issuing Body: ${profileDetails?["issuing_body"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
              Text('Issuance Date: ${profileDetails?["issuance_date"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
              Text('Expiration Date: ${profileDetails?["expiration_date"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
            ],
          ),
      ],
    );
  }


  void _openDocumentPreview(dynamic urlData, String title) {
    if (urlData == null || urlData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document available')),
      );
      return;
    }

    // Extract the first URL if it's a JSON array as a string
    final String url;
    if (urlData is String && urlData.startsWith('[')) {
      try {
        List<dynamic> urls = List<dynamic>.from(Uri.decodeComponent(urlData).replaceAll('"', '').replaceAll('[', '').replaceAll(']', '').split(','));
        url = urls.isNotEmpty ? urls.first.trim() : '';
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid document URL format')),
        );
        return;
      }
    } else if (urlData is List && urlData.isNotEmpty) {
      url = urlData.first.toString();
    } else {
      url = urlData.toString();
    }

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          height: 300,
                          width: double.infinity,
                          child: const Center(
                            child: Text(
                              'Failed to load document',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
