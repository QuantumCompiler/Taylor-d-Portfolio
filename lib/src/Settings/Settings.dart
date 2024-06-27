// Imports
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Themes/Themes.dart';
import 'Context/SettingsContext.dart';

/*  SettingsPage - Page for settings in the application
      Constructor:
        Input:
          key: Key
      Algorithm:
          * Build scaffold with app bar and body
          * Populate body with settings
      Output:
          Returns a Scaffold with settings for the application
*/
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: appBar(context),
      body: bodyContent(context, theme),
    );
  }
}
