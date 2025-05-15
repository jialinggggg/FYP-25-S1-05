import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_page.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mmyzsijycjxdkxglrxxl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1teXpzaWp5Y2p4ZGt4Z2xyeHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcxNjM3MDEsImV4cCI6MjA1MjczOTcwMX0.kc1OUjoORjgnx2W3N5hG_LNwjvh1OZfy9r3M4-mq4_I',
  );

  runApp(const MyWebApp());

}

class MyWebApp extends StatelessWidget {
  const MyWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
