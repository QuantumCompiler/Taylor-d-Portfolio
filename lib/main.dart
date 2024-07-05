import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/Dashboard/Dashboard.dart';
import 'src/Globals/Globals.dart';
import 'src/Themes/Themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  CreateApplicationsDir();
  CreateJobsDir();
  CreateProfileDir();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          home: Dashboard(),
          theme: themeProvider.themeData,
        );
      },
    );
  }
}
