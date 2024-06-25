import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Globals/Globals.dart';
import '../Profile/ProfileUtils.dart';
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
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          settingsTitle,
          style: TextStyle(
            fontSize: appBarTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * settingsTileContainerWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SwitchListTile(
                title: Text(
                  settingsCurrentTheme,
                ),
                value: themeProvider.isDarkTheme,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              ),
              ListTile(
                title: Text(
                  settingsDeleteAllProfiles,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(
                          'Delete All Profiles',
                          style: TextStyle(
                            fontSize: appBarTitle,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        content: Text(
                          'Would you like to delete all profiles? This cannot be undone.',
                          textAlign: TextAlign.center,
                        ),
                        actions: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  'Cancel',
                                ),
                              ),
                              SizedBox(width: standardSizedBoxWidth),
                              ElevatedButton(
                                onPressed: () {
                                  DeleteAllProfiles();
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  'Delete',
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                  // DeleteAllProfiles();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
