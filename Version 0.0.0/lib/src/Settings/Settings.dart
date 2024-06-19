import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Profile/ProfileFunctions.dart';
import '../Themes/Themes.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: Container(
          width: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SwitchListTile(
                title: Text('Dark Theme'),
                value: themeProvider.isDarkTheme,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              ),
              ListTile(
                title: Text('Delete All Profiles'),
                onTap: () {
                  DeleteAllProfiles(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
