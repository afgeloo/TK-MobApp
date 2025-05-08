import 'package:flutter/material.dart';
import 'blogs.dart';
import 'package:provider/provider.dart';
import 'widgets/notification_service.dart';

void main() async {
  // This is required for async operations in main
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification manager
  final notificationManager = NotificationManager();
  await notificationManager.initialize();
  
  runApp(
    // Wrap with ChangeNotifierProvider
    ChangeNotifierProvider.value(
      value: notificationManager,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tara Kabataan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const BlogsPage(), 
    );
  }
}