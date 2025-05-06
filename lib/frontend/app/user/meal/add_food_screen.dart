import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../backend/supabase/meal_entries_service.dart';
import '../../../../services/spoonacular_api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

class AddFoodScreen extends StatefulWidget {
  final String mealType;

  const AddFoodScreen({super.key, required this.mealType});

  @override
  AddFoodScreenState createState() => AddFoodScreenState();
}

class AddFoodScreenState extends State<AddFoodScreen> {
  final SpoonacularApiService _spoonacularApiService = SpoonacularApiService();
  final MealEntriesService _mealEntriesService = MealEntriesService(Supabase.instance.client);
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _loggedMeals = [];
  List<Map<String, dynamic>> _searchResults = [];
  final List<Map<String, dynamic>> _selectedMeals = [];

  @override
  void initState() {
    super.initState();
    _fetchLoggedMeals();
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
      await _searchMeals(bestFoodMatch);
    } catch (e) {
      print('Food recognition error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _fetchLoggedMeals() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final meals = await _mealEntriesService.fetchMealEntries(userId);
      setState(() {
        _loggedMeals = meals
            .where((meal) =>
                meal['type'] == widget.mealType &&
                DateTime.parse(meal['created_at']).isAfter(startOfDay) &&
                DateTime.parse(meal['created_at']).isBefore(endOfDay))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching logged meals: $e')),
        );
      }
    }
  }

  Future<void> _searchMeals(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      final results = await _spoonacularApiService.searchMeals(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching meals: $e')),
        );
      }
    }
  }

  void _addMeal(Map<String, dynamic> meal) {
    setState(() {
      _selectedMeals.add(meal);
    });
  }

  void _removeMeal(int index, bool isLoggedMeal) {
    setState(() {
      if (isLoggedMeal) {
        _loggedMeals[index]['markedForDeletion'] = true;
      } else {
        _selectedMeals.removeAt(index - _loggedMeals.length);
      }
    });
  }

  Future<void> _saveMeals() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      for (var meal in _loggedMeals) {
        if (meal['markedForDeletion'] == true) {
          await _mealEntriesService.deleteMealEntry(meal['meal_id']);
        }
      }

      for (var meal in _selectedMeals) {
        await _mealEntriesService.insertMealEntry(
          spoonacularId: meal['id'],
          uid: userId,
          name: meal['title'],
          calories: _getCalories(meal),
          carbs: _getNutrientValue(meal, 'Carbohydrates'),
          protein: _getNutrientValue(meal, 'Protein'),
          fats: _getNutrientValue(meal, 'Fat'),
          type: widget.mealType,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meals saved successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving meals: $e')),
        );
      }
    }
  }

  int _getCalories(Map<String, dynamic> meal) {
    final nutrients = meal['nutrition']['nutrients'] as List<dynamic>;
    final nutrient = nutrients.firstWhere(
      (n) => n['name'] == 'Calories',
      orElse: () => {'amount': 0.0},
    );
    return nutrient['amount'].toInt();
  }

  double _getNutrientValue(Map<String, dynamic> meal, String nutrientName) {
    final nutrients = meal['nutrition']['nutrients'] as List<dynamic>;
    final nutrient = nutrients.firstWhere(
      (n) => n['name'] == nutrientName,
      orElse: () => {'amount': 0.0},
    );
    return nutrient['amount'] as double;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.mealType, style: const TextStyle(color: Colors.black, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: MediaQuery.of(context).size.height / 3,
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Nutrition Logged",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (_loggedMeals.isEmpty && _selectedMeals.isEmpty)
                  const Center(
                    child: Text("Nothing here yet! Add your meal to see your progress."),
                  ),
                if (_loggedMeals.isNotEmpty || _selectedMeals.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _loggedMeals.length + _selectedMeals.length,
                      itemBuilder: (context, index) {
                        final isLoggedMeal = index < _loggedMeals.length;
                        final meal = isLoggedMeal
                            ? _loggedMeals[index]
                            : _selectedMeals[index - _loggedMeals.length];

                        if (isLoggedMeal && meal['markedForDeletion'] == true) {
                          return const SizedBox.shrink();
                        }

                        return ListTile(
                          title: Text(meal['title'] ?? meal['name']),
                          subtitle: Text(
                            'Calories: ${isLoggedMeal ? meal['calories'] : _getCalories(meal)} kcal | '
                            'Carbs: ${isLoggedMeal ? meal['carbs'] : _getNutrientValue(meal, 'Carbohydrates').toStringAsFixed(2)}g | '
                            'Protein: ${isLoggedMeal ? meal['protein'] : _getNutrientValue(meal, 'Protein').toStringAsFixed(2)}g | '
                            'Fats: ${isLoggedMeal ? meal['fats'] : _getNutrientValue(meal, 'Fat').toStringAsFixed(2)}g',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => _removeMeal(index, isLoggedMeal),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for meals...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: _searchMeals,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Recognition"),
                        onPressed: _recognizeFoodFromImage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_searchResults.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final meal = _searchResults[index];
                          return ListTile(
                            title: Text(meal['title']),
                            subtitle: Text(
                              'Calories: ${_getCalories(meal)} kcal | '
                              'Carbs: ${_getNutrientValue(meal, 'Carbohydrates')}g | '
                              'Protein: ${_getNutrientValue(meal, 'Protein')}g | '
                              'Fats: ${_getNutrientValue(meal, 'Fat')}g',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _addMeal(meal),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.green,
        height: 60,
        child: InkWell(
          onTap: _saveMeals,
          child: const Center(
            child: Text(
              "Save",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
