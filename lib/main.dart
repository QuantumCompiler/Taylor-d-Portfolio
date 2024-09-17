import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/Dashboard/Dashboard.dart';
import 'src/Utilities/GlobalUtils.dart';
import 'src/Themes/Themes.dart';
import 'package:get/get.dart';

void main() async {
  Get.config(enableLog: false);
  await StartUp();
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
