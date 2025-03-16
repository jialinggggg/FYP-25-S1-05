import 'package:flutter/material.dart';

class RecipeDetailPage extends StatefulWidget {
  final Map<String, String> recipe;
  final Function(String, String) onStatusChanged;

  const RecipeDetailPage({super.key, required this.recipe, required this.onStatusChanged});

  @override
  RecipeDetailPageState createState() => RecipeDetailPageState();
}

class RecipeDetailPageState extends State<RecipeDetailPage> {
  late String status;

  @override
  void initState() {
    super.initState();
    status = widget.recipe["status"]!;
  }

  ///Function to Update Status
  void _updateStatus(String newStatus) {
    setState(() {
      status = newStatus;
    });

    widget.onStatusChanged(widget.recipe["title"]!, newStatus);
  }

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Recipe Details",
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: isWideScreen
            ? EdgeInsets.symmetric(horizontal: 100, vertical: 20)
            : EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ///Recipe Image
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  widget.recipe["image"]!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 20),

            ///Recipe Title
            Text(
              widget.recipe["title"]!,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 10),

            ///Recipe Calories, Time, Difficulty
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.black54, size: 20),
                    SizedBox(width: 5),
                    Text("302 kcal", style: TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
                SizedBox(width: 15),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.black54, size: 20),
                    SizedBox(width: 5),
                    Text("10 minutes", style: TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
                SizedBox(width: 15),
                Row(
                  children: [
                    Icon(Icons.assignment_turned_in, color: Colors.black54, size: 20),
                    SizedBox(width: 5),
                    Text("Easy", style: TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),

            ///Recipe Description
            Text(
              "Crispy toast topped with your favorite morning flavors—simple and satisfying.",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 15),

            Divider(color: Colors.black26),
            SizedBox(height: 15),

            ///Current Status
            Row(
              children: [
                Text(
                  "Status: ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: status == "Approved"
                        ? Colors.green
                        : status == "Rejected"
                        ? Colors.red
                        : Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            ///Ingredients Section
            Text(
              "Ingredients",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 10),
            _buildBulletPoint("2 slices of bread (whole grain, sourdough, or multigrain)"),
            _buildBulletPoint("1 egg"),
            _buildBulletPoint("1/2 an avocado"),
            _buildBulletPoint("Handful of spinach"),
            _buildBulletPoint("Salt and pepper, to taste"),
            SizedBox(height: 20),

            ///Instructions Section
            Text(
              "Instructions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 10),
            _buildNumberedStep(1, "Toast the 2 slices of bread until golden and crispy. You can use a toaster or a grill pan for extra crispiness."),
            _buildNumberedStep(2, "While the bread is toasting, heat a small non-stick pan over medium heat. Crack the egg into the pan and cook it to your liking (fried, scrambled, or poached). Season with salt and pepper."),
            _buildNumberedStep(3, "While the egg is cooking, scoop out the flesh of the avocado and mash it in a bowl. Add a pinch of salt and pepper to taste, and mix it up."),
            _buildNumberedStep(4, "In the same pan used for the egg, quickly sauté the spinach for about 1-2 minutes until wilted. You can add a little olive oil or butter if desired."),
            _buildNumberedStep(5, "Serve it on a plate. Season with a little more salt and pepper on top of the egg. Optionally, add some chili flakes or a drizzle of olive oil for extra flavor."),
            SizedBox(height: 30),

            ///Approval Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 300),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.black26),
                ),
                child: Row(
                  children: [
                    ///Approve Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _updateStatus("Approved");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: status == "Approved" ? Colors.green : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          side: status == "Approved" ? BorderSide.none : BorderSide(color: Colors.black26),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, color: status == "Approved" ? Colors.white : Colors.black87, size: 18),
                            SizedBox(width: 5),
                            Text(
                              "Approved",
                              style: TextStyle(
                                fontSize: 16,
                                color: status == "Approved" ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    ///Reject Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _updateStatus("Rejected");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: status == "Rejected" ? Colors.red : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          side: status == "Rejected" ? BorderSide.none : BorderSide(color: Colors.black26),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close, color: status == "Rejected" ? Colors.white : Colors.black87, size: 18),
                            SizedBox(width: 5),
                            Text(
                              "Reject",
                              style: TextStyle(
                                fontSize: 16,
                                color: status == "Rejected" ? Colors.white : Colors.black87,
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

  ///Bullet Point List
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 6, color: Colors.black87),
          SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 16, color: Colors.black87))),
        ],
      ),
    );
  }

  ///Numbered Steps
  Widget _buildNumberedStep(int step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$step.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 16, color: Colors.black87))),
        ],
      ),
    );
  }
}
