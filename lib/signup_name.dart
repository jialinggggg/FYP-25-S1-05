import 'package:flutter/material.dart';

class SignupName extends StatelessWidget {
  const SignupName({super.key}); // Add key parameter to constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Enter your name',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle the signup action here
              },
              child: Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
