import 'package:flutter/material.dart';
import 'profile_page.dart'; // Unified Profile Page
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import '../../../backend/supabase/accounts_service.dart';
import 'package:intl/intl.dart';

class ManageAccountsPage extends StatefulWidget {
  const ManageAccountsPage({super.key});

  @override
  ManageAccountsPageState createState() => ManageAccountsPageState();
}

class ManageAccountsPageState extends State<ManageAccountsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  final AccountService _accountService = AccountService(Supabase.instance.client);

  List<Map<String, dynamic>> userAccounts = [];
  List<Map<String, dynamic>> businessAccounts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.toLowerCase();
      });
    });
    _fetchAccounts();
  }

  /// Fetch all accounts from the database
  Future<void> _fetchAccounts() async {
    try {
      final userAccountsData = await _accountService.fetchAllUserAccounts();
      final businessAccountsData = await _accountService.fetchAllBusinessAccounts();

      debugPrint('Fetched User Accounts: $userAccountsData'); // Debug log
      debugPrint('Fetched Business Accounts: $businessAccountsData'); // Debu

      if (mounted) {
        setState(() {
          userAccounts = userAccountsData;
          businessAccounts = businessAccountsData;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching accounts: $e')),
        );
      }
    }
  }

  /// **🔹 Updates the account data**
  Future<void> _updateAccount(String uid, Map<String, String> updatedData, bool isUser) async {
    try {
      if (isUser) {
        await _accountService.updateAccount(
          uid: uid,
          email: updatedData["email"]!,
          type: updatedData["type"]!,
          status: updatedData["status"]!,
        );
      } else {
        await _accountService.updateAccount(
          uid: uid,
          email: updatedData["email"]!,
          type: updatedData["type"]!,
          status: updatedData["status"]!,
        );
      }
      if (mounted) {
        await _fetchAccounts(); // Refresh the data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating account: $e')),
        );
      }
    }
  }

  /// **🔹 Deletes an account from the list**
  Future<void> _deleteAccount(String uid, bool isUser) async {
    try {
      await _accountService.deleteAccount(uid: uid);
      if (mounted) {
        await _fetchAccounts(); // Refresh the data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: isWideScreen ? 100 : 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ///Tabs for Users & Business Partners
            TabBar(
              controller: _tabController,
              labelColor: Colors.green[800],
              unselectedLabelColor: Colors.black,
              indicatorColor: Colors.green[800],
              labelStyle: const TextStyle(
                fontSize: 18,  // ✅ Set active tab font size
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,  // ✅ Set inactive tab font size
              ),
              tabs: const [
                Tab(text: "Users"),
                Tab(text: "Business Partner"),
              ],
            ),
            const SizedBox(height: 10),

            ///Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for Account",
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),

            ///Tabs Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAccountsTable(userAccounts, true),
                  _buildAccountsTable(businessAccounts, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///Builds Accounts Table for Users & Business Partners
Widget _buildAccountsTable(List<Map<String, dynamic>> accounts, bool isUser) {
  final filteredAccounts = accounts.where((account) {
    return account["name"]?.toLowerCase().contains(searchQuery) ?? false ||
        account["email"]?.toLowerCase().contains(searchQuery) ?? false ||
        account["status"]?.toLowerCase().contains(searchQuery) ?? false;
  }).toList();

  return filteredAccounts.isEmpty
      ? Center(
          child: Text(
            "No accounts found",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        )
      : SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: isUser
                ? const [
                    DataColumn(label: Text("No.")),
                    DataColumn(label: Text("Name")),
                    DataColumn(label: Text("Email")),
                    DataColumn(label: Text("Status")),
                    DataColumn(label: Text("Country")),
                    DataColumn(label: Text("Birth Date")),
                    DataColumn(label: Text("Gender")),
                    DataColumn(label: Text("Created At")),
                    DataColumn(label: Text("Actions")),
                  ]
                : const [
                    DataColumn(label: Text("No.")),
                    DataColumn(label: Text("Business Name")),
                    DataColumn(label: Text("Email")),
                    DataColumn(label: Text("Status")),
                    DataColumn(label: Text("Registration No.")),
                    DataColumn(label: Text("Type")),
                    DataColumn(label: Text("Country")),
                    DataColumn(label: Text("Created At")),
                    DataColumn(label: Text("Actions")),
                  ],
            rows: List<DataRow>.generate(
              filteredAccounts.length,
              (index) {
                final account = filteredAccounts[index];
                final businessProfile = account["business_profiles"] as Map<String, dynamic>?;
                final userProfile = account["user_profiles"] as Map<String, dynamic>?;

                return DataRow(
                  cells: isUser
                      ? [
                          DataCell(Text((index + 1).toString())),
                          DataCell(Text(userProfile?["name"] ?? "N/A")),
                          DataCell(Text(account["email"] ?? "N/A")),
                          DataCell(
                            Text(
                              account["status"] ?? "N/A",
                              style: TextStyle(
                                color: account["status"] == "active" ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(Text(userProfile?["country"] ?? "N/A")),
                          DataCell(
                            Text(
                              userProfile?["birth_date"] != null
                                  ? DateFormat('yyyy-MM-dd').format(
                                      DateTime.parse(userProfile!["birth_date"].toString()),
                                  )
                                  : "N/A",
                            ),
                          ),
                          DataCell(Text(userProfile?["gender"] ?? "N/A")),
                          DataCell(Text(account["created_at"] ?? "N/A")),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.arrow_forward, color: Colors.green),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfilePage(
                                      account: account,
                                      onUpdate: _updateAccount,
                                      onDelete: _deleteAccount,
                                      isBusiness: !isUser,
                                    ),
                                  ),
                                );

                                if (result != null && mounted) {
                                  if (result["deleted"] == true) {
                                    await _deleteAccount(result["uid"], isUser);
                                  } else {
                                    await _updateAccount(result["uid"], result["updatedData"], isUser);
                                  }
                                }
                              },
                            ),
                          ),
                        ]
                      : [
                          DataCell(Text((index + 1).toString())),
                          DataCell(Text(businessProfile?["name"] ?? "N/A")),
                          DataCell(Text(account["email"] ?? "N/A")),
                          DataCell(
                            Text(
                              account["status"] ?? "N/A",
                              style: TextStyle(
                                color: account["status"] == "active" ? Colors.green : const Color.fromARGB(255, 244, 219, 54),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(Text(businessProfile?["registration_no"] ?? "N/A")),
                          DataCell(Text(businessProfile?["type"] ?? "N/A")),
                          DataCell(Text(businessProfile?["country"] ?? "N/A")),
                          DataCell(Text(account["created_at"] ?? "N/A")),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.arrow_forward, color: Colors.green),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfilePage(
                                      account: account,
                                      onUpdate: _updateAccount,
                                      onDelete: _deleteAccount,
                                      isBusiness: !isUser,
                                    ),
                                  ),
                                );

                                if (result != null && mounted) {
                                  if (result["deleted"] == true) {
                                    await _deleteAccount(result["uid"], isUser);
                                  } else {
                                    await _updateAccount(result["uid"], result["updatedData"], isUser);
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                );
              },
            ),
          ),
        );
}
}