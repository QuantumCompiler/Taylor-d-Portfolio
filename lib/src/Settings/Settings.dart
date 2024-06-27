// Imports
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Globals/Globals.dart';
import '../Jobs/JobsUtils.dart';
import '../Profile/ProfileUtils.dart';
import '../Themes/Themes.dart';

/* Parameters
    settingsTileContainerWidth: Double for width of the settings tile container
    settingsCurrentTheme: String for current theme setting
    settingsDeleteAllProfiles: String for delete all profiles setting
    settingsDeleteAllJobs: String for delete all jobs setting
*/
double settingsTileContainerWidth = 0.6;
String settingsCurrentTheme = 'Switch Theme';
String settingsDeleteAllProfiles = 'Delete All Profiles';
String settingsDeleteAllJobs = 'Delete All Jobs';

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (isDesktop()) {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            } else if (isMobile()) {
              Navigator.of(context).pop();
            }
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
              switchTheme(themeProvider),
              delJobs(context),
              delProfs(context),
            ],
          ),
        ),
      ),
    );
  }
}

/*  switchTheme - Switch for toggling between light and dark theme
      Input:
        theme: ThemeProvider built from the ThemeProvider class
      Output:
          Returns a SwitchListTile for toggling between light and dark theme
*/
SwitchListTile switchTheme(ThemeProvider theme) {
  return SwitchListTile(
    title: Text(
      settingsCurrentTheme,
    ),
    value: theme.isDarkTheme,
    onChanged: (value) {
      theme.toggleTheme();
    },
  );
}

/*  delJobs - Delete all jobs
      Input:
        context: BuildContext
      Algorithm:
          * Show dialog to confirm deletion of all jobs
          * Call DeleteAllJobs function if confirmed in the context of the platformDetect function
      Output:
          Returns a ListTile for deleting all jobs
*/
ListTile delJobs(BuildContext context) {
  return ListTile(
    title: Text(
      settingsDeleteAllJobs,
    ),
    onTap: () {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              'Delete All Jobs',
              style: TextStyle(
                fontSize: appBarTitle,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              'Would you like to delete all jobs? This cannot be undone.',
              textAlign: TextAlign.center,
            ),
            actions: [
              platformDetect(context, DeleteAllJobs),
            ],
          );
        },
      );
    },
  );
}

/*  delProfs - Delete all profiles
      Input:
        context: BuildContext
      Algorithm:
          * Show dialog to confirm deletion of all profiles
          * Call DeleteAllProfiles function if confirmed in the context of the platformDetect function
      Output:
          Returns a ListTile for deleting all profiles
*/
ListTile delProfs(BuildContext context) {
  return ListTile(
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
              platformDetect(context, DeleteAllProfiles),
            ],
          );
        },
      );
    },
  );
}

/*  platformDetect - Detects the platform and returns the appropriate row
      Input:
        context: BuildContext
        func: VoidCallback
      Algorithm:
          * If the platform is desktop, return an ElevatedButton for cancel and delete
          * If the platform is mobile, return an IconButton for cancel and delete
      Output:
          Returns a Row with the appropriate buttons for the platform
*/
Row platformDetect(BuildContext context, VoidCallback func) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (isDesktop()) ...[
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancel',
          ),
        ),
      ] else if (isMobile()) ...[
        IconButton(
          icon: Icon(Icons.cancel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
      SizedBox(width: standardSizedBoxWidth),
      if (isDesktop()) ...[
        ElevatedButton(
          onPressed: () {
            func();
            Navigator.of(context).pop();
          },
          child: Text(
            'Delete',
          ),
        ),
      ] else if (isMobile()) ...[
        IconButton(
          icon: Icon(Icons.save),
          onPressed: () {
            func();
            Navigator.of(context).pop();
          },
        ),
      ]
    ],
  );
}
