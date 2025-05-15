import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nutri_app/backend/entities/nutrition.dart';
import 'package:nutri_app/backend/entities/recipes.dart';
import 'package:nutri_app/backend/entities/meal_log.dart';
import 'package:nutri_app/backend/controllers/fetch_recipe_for_meal_log_controller.dart';
import 'package:nutri_app/backend/controllers/search_recipe_by_name_controller.dart';
import 'package:nutri_app/backend/controllers/log_meal_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; 
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

class LogMealScreen extends StatefulWidget {
  final String mealType;
  final DateTime selectedDate;
  
  const LogMealScreen({super.key, required this.mealType, required this.selectedDate});

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = _supabase.auth.currentUser!.id;
      _fetchRecipes(uid, 'Recent');
      _fetchLoggedMeals(uid);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _recognizeFoodFromImage() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required')),
          );
        }
        return;
      }

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final bytes = await File(pickedFile.path).readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Image file is empty');
      }

      if (bytes.lengthInBytes > 10 * 1024 * 1024) {
        throw Exception('Image is too large (max 10MB)');
      }

      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      const targetWidth = 800;
      final targetHeight = (image.height * (targetWidth / image.width)).toInt();

      final resizedImage = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
      );

      final jpgBytes = img.encodeJpg(resizedImage, quality: 85);
      final base64Image = base64Encode(jpgBytes);

      const apiKey = 'AIzaSyB_hTILl0ruoHg_-NmerTbi03D7JRvY57k';
      const url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "requests": [
            {
              "image": {"content": base64Image},
              "features": [
                {"type": "LABEL_DETECTION", "maxResults": 10},
                {"type": "WEB_DETECTION", "maxResults": 5}
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body)['error'] ?? {};
        throw Exception('API error: ${error['message'] ?? 'Unknown error'}');
      }

      final responseData = jsonDecode(response.body);
      final firstResponse = responseData['responses'][0];

      final labels = (firstResponse['labelAnnotations'] ?? [])
          .map<String>((l) => l['description']?.toString() ?? '')
          .toList();

      final webEntities = (firstResponse['webDetection']?['webEntities'] ?? [])
          .map<String>((w) => w['description']?.toString() ?? '')
          .toList();

      final allResults = [...labels, ...webEntities].toSet().toList();

      if (allResults.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not recognize any food in the image')),
          );
        }
        return;
      }

      const foodKeywords = [
        'food', 'fruit', 'vegetable', 'meal', 'dish', 'banana', 'apple',
        'rice', 'pasta', 'bread', 'meat', 'chicken', 'fish'
      ];

      String bestFoodMatch = allResults.firstWhere(
        (item) => foodKeywords.any((keyword) => item.toLowerCase().contains(keyword)),
        orElse: () => allResults.first,
      );

      _searchController.text = bestFoodMatch;
      final searchController = Provider.of<SearchRecipeByNameController>(context, listen: false);
      searchController.setSearchQuery(bestFoodMatch);
      searchController.searchRecipes(bestFoodMatch);
      setState(() {
        _isSearching = true;
      });
    } catch (e) {
      print('Food recognition error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _fetchRecipes(String uid, String tab) {
    final controller = Provider.of<FetchRecipeForMealLogController>(context, listen: false);
    controller.fetchRecipes(uid, tab);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        String selectedTab = '';
        if (_tabController.index == 0) {
          selectedTab = 'Recent';
        } else if (_tabController.index == 1) {
          selectedTab = 'Favourite';
        } else if (_tabController.index == 2) {
          selectedTab = 'Created';
        }
        controller.fetchRecipes(uid, selectedTab);
      }
    });
  }

  void _fetchLoggedMeals(String uid) {
    final controller = Provider.of<LogMealController>(context, listen: false);
    controller.fetchLoggedMeals(uid, widget.selectedDate, widget.mealType);
  }

  void _showAddedMeals() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final viewLoggedMealsController = Provider.of<LogMealController>(context, listen: false);
            return Container(
              padding: const EdgeInsets.all(16),
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Added Meals',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Consumer<LogMealController>(
                      builder: (context, controller, child) {
                        return _buildRecipeList(
                          items: controller.loggedMeals,
                          isSearching: controller.isLoading,
                          onAddMeal: (mealLog) {
                            viewLoggedMealsController.removeLogMeal(mealLog.mealId);
                          },
                          isAddedMeal: true,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text('${widget.mealType} Log', style: const TextStyle(color: Colors.green, fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.green),
            onPressed: _showAddedMeals,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            if (!_isSearching) _buildTabBar(),
            Expanded(
              child: _isSearching
                  ? _buildSearchResults()
                  : _buildTabViews(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildSaveButton(),
    );
  } 

  Widget _buildSearchBar() {
    return Consumer<SearchRecipeByNameController>(
      builder: (context, searchController, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    hintText: "Search meals...",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (value) {
                    searchController.setSearchQuery(value);
                    if (value.isNotEmpty) {
                      searchController.searchRecipes(value);
                      setState(() {
                        _isSearching = true;
                      });
                    } else {
                      setState(() {
                        _isSearching = false;
                      });
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.green),
                onPressed: _recognizeFoodFromImage,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Recent'),
        Tab(text: 'Favourite'),
        Tab(text: 'Created'),
      ],
      indicatorColor: Colors.green,
      labelColor: Colors.green,
      unselectedLabelColor: Colors.grey,
    );
  }

  Widget _buildTabViews() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildMealList('Recent'),
        _buildMealList('Favourite'),
        _buildMealList('Created'),
      ],
    );
  }

  Widget _buildMealList(String tab) {
    return Consumer<FetchRecipeForMealLogController>(
      builder: (context, controller, child) {
        final viewLoggedMealsController = Provider.of<LogMealController>(context, listen: false);
        return _buildRecipeList(
          items: controller.recipes,
          isSearching: controller.isLoading,
          onAddMeal: (recipe) async {
            final uid = _supabase.auth.currentUser!.id;
            viewLoggedMealsController.addLogMeal(recipe, uid, widget.mealType, widget.selectedDate);

            // After adding, show updated bottom sheet
            await Future.delayed(Duration(milliseconds: 100)); // slight delay for state update
            _showAddedMeals();
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return Consumer<SearchRecipeByNameController>(
      builder: (context, searchController, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (searchController.searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Search results for: ${searchController.searchQuery}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        searchController.clearSearch();
                        setState(() {
                          _isSearching = false;
                        });
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 16, color: Colors.green, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _buildRecipeList(
                items: searchController.searchResults,
                isSearching: searchController.isSearching,
                onAddMeal: (recipe) async {
                  final uid = _supabase.auth.currentUser!.id;
                  final viewLoggedMealsController = Provider.of<LogMealController>(context, listen: false);
                  viewLoggedMealsController.addLogMeal(recipe, uid, widget.mealType, widget.selectedDate);

                  // After adding, show updated bottom sheet
                  await Future.delayed(Duration(milliseconds: 100));
                  _showAddedMeals();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecipeList({
    required List<dynamic> items, // List<Recipes> or List<MealLog>
    required bool isSearching,
    required Function(dynamic) onAddMeal,
    bool isAddedMeal = false, // true = logged meals (remove mode)
  }) {
    if (isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return const Center(child: Text('No meals found.'));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        String title;
        String imageUrl = 'https://via.placeholder.com/150'; // default
        double calories;

        if (item is Recipes) {
          title = item.title;
          imageUrl = item.image ?? 'https://via.placeholder.com/150';
          calories = item.nutrition?.nutrients.firstWhere(
            (nutrient) => nutrient.title.toLowerCase().contains('calories'),
            orElse: () => Nutrient(title: 'Calories', amount: 0, unit: 'kcal'),
          ).amount ?? 0;
        } 
        else if (item is MealLog) {
          title = item.mealName;
          calories = item.nutrition.nutrients.firstWhere(
            (nutrient) => nutrient.title.toLowerCase().contains('calories'),
            orElse: () => Nutrient(title: 'Calories', amount: 0, unit: 'kcal'),
          ).amount;
          imageUrl = item.image;
        } 
        else {
          return const SizedBox(); // unknown type
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: Image.network(
              imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
            title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                  const SizedBox(width: 5),
                  Text(
                    '${calories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                isAddedMeal ? Icons.remove_circle_outline : Icons.add_circle_outline,
                color: isAddedMeal ? Colors.red : Colors.green,
              ),
              onPressed: () => onAddMeal(item),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () async {
          final viewLoggedMealsController = Provider.of<LogMealController>(context, listen: false);
          try {
            // Call the saveMeals method to insert or delete meals from the database
            await viewLoggedMealsController.saveMeals();

            // Show success message in the current screen
            if (mounted){
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Meals saved successfully!'), backgroundColor: Colors.green,),
              );
              // Navigate back to the main_log_screen and pass a success message
              Navigator.pushNamed(context, '/log');
            }
          } catch (e) {
            if (mounted){
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to save meals: $e')),
              );

              // Navigate back to the main_log_screen and pass an error message
              Navigator.pop(context, 'Failed to save meals: $e');
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Save',
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}