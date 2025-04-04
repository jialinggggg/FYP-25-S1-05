import 'package:flutter/material.dart';
import '../business/signup_biz_profile.dart';
import '../../../../backend/state/signup_state.dart'; // Import your SignupState
import 'package:provider/provider.dart'; // Import Provider

class SignupType extends StatefulWidget {
  const SignupType({super.key});

  @override
  SignupTypeState createState() => SignupTypeState();
}

class SignupTypeState extends State<SignupType> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            Text(
              "Choose Your Role",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // User Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Clear state before navigation
                  Provider.of<SignupState>(context, listen: false).clearAll();
                  Navigator.pushNamed(
                    context,
                    '/signup_welcome',
                    );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  "User",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Business Partner Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Clear state before navigation
                  Provider.of<SignupState>(context, listen: false).clearAll();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignupBizProfile(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  "Business Partner",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}