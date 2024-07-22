// Imports
import 'package:flutter/material.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Globals/SettingsGlobals.dart';
import '../../Globals/Globals.dart';
import '../../Utilities/GlobalUtils.dart';
import '../../Utilities/SettingsUtilities.dart';
import '../../Themes/Themes.dart';

/*  appBar - App bar for the settings page
      Input:
        context: BuildContext of the application
      Algorithm:
          * Return an AppBar with a back button and title
      Output:
          Returns an AppBar with a back button and title
*/
AppBar appBar(BuildContext context) {
  return AppBar(
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_outlined),
      onPressed: () {
        Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: Dashboard()), (Route<dynamic> route) => false);
      },
    ),
    actions: [
      Row(
        children: [
          IconButton(
            icon: Icon(Icons.dashboard),
            onPressed: () {
              Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: Dashboard()), (Route<dynamic> route) => false);
            },
          ),
        ],
      ),
    ],
    title: Text(
      settingsTitle,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/*  bodyContent - Body content for the settings page
      Input:
        context: BuildContext
        theme: ThemeProvider built from the ThemeProvider class
      Algorithm:
          * Return a center widget with a container for the settings
          * Populate the container with a column of settings
      Output:
          Returns a Center widget with a container for the settings
*/
Center bodyContent(BuildContext context, ThemeProvider theme) {
  return Center(
    child: Container(
      width: MediaQuery.of(context).size.width * settingsTileContainerWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          switchTheme(theme),
          // delJobs(context),
          // delProfs(context),
          setLatexDirectory(context),
        ],
      ),
    ),
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

ListTile setLatexDirectory(BuildContext context) {
  return ListTile(
    title: Text(
      'Upload Main LaTeX Directory',
    ),
    onTap: () async {
      await pickAndCopy('Main LaTeX');
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
