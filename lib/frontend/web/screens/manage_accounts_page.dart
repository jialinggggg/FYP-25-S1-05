import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../backend/controller/accounts_controller.dart';

class ManageAccountsPage extends StatefulWidget {
  const ManageAccountsPage({super.key});

  @override
  ManageAccountsPageState createState() => ManageAccountsPageState();
}

class ManageAccountsPageState extends State<ManageAccountsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  String selectedStatus = "All";
  bool _isLoadingAccounts = false;

  final AccountsController _accountsController = AccountsController(Supabase.instance.client);

  List<Map<String, dynamic>> userAccounts = [];
  List<Map<String, dynamic>> businessAccounts = [];
  List<Map<String, dynamic>> nutritionistAccounts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.toLowerCase();
      });
    });
    _fetchAccounts();
  }

  Future<void> _fetchAccounts() async {
    setState(() {
      _isLoadingAccounts = true;
    });

    try {
      final userAccountsData = await _accountsController.fetchAllUserAccounts();
      final businessAccountsData = await _accountsController.fetchAllBusinessAccounts();
      final nutritionistAccountsData = await _accountsController.fetchAllNutritionistAccounts();

      if (mounted) {
        setState(() {
          userAccounts = userAccountsData;
          businessAccounts = businessAccountsData;
          nutritionistAccounts = nutritionistAccountsData;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching accounts: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAccounts = false;
        });
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
            /// Tabs for Users, Business Partners, and Nutritionists
            TabBar(
              controller: _tabController,
              labelColor: Colors.green[800],
              unselectedLabelColor: Colors.black,
              indicatorColor: Colors.green[800],
              labelStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
              ),
              tabs: const [
                Tab(text: "Users"),
                Tab(text: "Businesses"),
                Tab(text: "Nutritionists"),
              ],
            ),
            const SizedBox(height: 10),

            /// Search Bar and Status Dropdown
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
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
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                    items: ["All", "Active", "Pending", "Suspended", "Rejected"]
                        .map((status) => DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    ))
                        .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            /// Tabs Content
            Expanded(
              child: _isLoadingAccounts
                  ? _buildLoadingIndicator()
                  : TabBarView(
                controller: _tabController,
                children: [
                  _buildAccountsTable(userAccounts),
                  _buildAccountsTable(businessAccounts),
                  _buildAccountsTable(nutritionistAccounts),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  /// Builds Accounts Table for Users, Business Partners, and Nutritionists
  Widget _buildAccountsTable(List<Map<String, dynamic>> accounts) {
    final filteredAccounts = accounts.where((account) {
      final name = (account["name"] ?? account["full_name"] ?? "")
          .toString()
          .toLowerCase();
      final email = (account["accounts"]?["email"] ?? "")
          .toString()
          .toLowerCase();
      final status = (account["accounts"]?["status"] ?? "Unknown").toString().toLowerCase();

      final matchesQuery = name.contains(searchQuery) || email.contains(searchQuery);
      final matchesStatus = selectedStatus == "All" || status == selectedStatus.toLowerCase();

      return matchesQuery && matchesStatus;
    }).toList();

    return filteredAccounts.isEmpty
        ? Center(
      child: Text(
        "No accounts found",
        style: TextStyle(fontSize: 16, color: Colors.black54),
      ),
    )
        : ListView.builder(
      shrinkWrap: true,
      itemCount: filteredAccounts.length,
      itemBuilder: (context, index) {
        final account = filteredAccounts[index];
        final name = account["name"] ?? account["full_name"] ?? "N/A";
        final email = account["accounts"]?["email"] ?? "N/A";
        final status = account["accounts"]?["status"] ?? "Unknown";
        final createdAt = account["created_at"]?.split('T')[0] ?? "Unknown";

        return Container(
          margin: EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("Email: $email", style: TextStyle(fontSize: 14)),
                    Text("Date: $createdAt", style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              if (status != "Unknown")
                Container(
                  margin: EdgeInsets.only(right: 10),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == "active"
                        ? Colors.green
                        : status == "pending"
                        ? Colors.amber
                        : status == "rejected"
                        ? Colors.red
                        : Colors.deepOrange,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, color: Colors.green),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(
                        uid: account["uid"],
                      ),
                    ),
                  ).then((_) => _fetchAccounts());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
