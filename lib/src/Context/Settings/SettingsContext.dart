// Imports
import 'package:flutter/material.dart';
import '../../Applications/Applications.dart';
import '../../Context/Globals/GlobalContext.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Globals/SettingsGlobals.dart';
import '../../Globals/Globals.dart';
import '../../Themes/Themes.dart';
import '../../Utilities/GlobalUtils.dart';
import '../../Utilities/SettingsUtilities.dart';

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
    title: Text(
      settingsTitle,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    leading: NavToPage(context, 'Dashboard', Icon(Icons.arrow_back_ios_new_outlined), Dashboard(), false, false),
    actions: [
      Row(
        children: [
          NavToPage(context, 'Applications', Icon(Icons.task), ApplicationsPage(), true, false),
          NavToPage(context, 'Dashboard', Icon(Icons.dashboard), Dashboard(), true, false),
        ],
      ),
    ],
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
      width: MediaQuery.of(context).size.width * 0.80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ExpansionTile(
            title: Text('Delete Content'),
            children: [
              SizedBox(height: standardSizedBoxHeight),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    delAll(context),
                    delApps(context),
                    delJobs(context),
                    delProfs(context),
                  ],
                ),
              ),
              SizedBox(height: standardSizedBoxHeight),
            ],
          ),
          ExpansionTile(
            title: Text('LaTeX'),
            children: [
              SizedBox(height: standardSizedBoxHeight),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    setLatexDirectory(context),
                  ],
                ),
              ),
              SizedBox(height: standardSizedBoxHeight),
            ],
          ),
          ExpansionTile(
            title: Text('Thematic'),
            children: [
              SizedBox(height: standardSizedBoxHeight),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    switchTheme(theme),
                  ],
                ),
              ),
              SizedBox(height: standardSizedBoxHeight),
            ],
          ),
        ],
      ),
    ),
  );
}

ListTile delAll(BuildContext context) {
  return ListTile(
    title: Text(
      'Delete All Content',
    ),
    onTap: () {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              'Delete All Applications',
              style: TextStyle(
                fontSize: appBarTitle,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              'Would you like to delete all content? This cannot be undone.',
              textAlign: TextAlign.center,
            ),
            actions: [
              platformDetect(context, DeleteAllContent),
            ],
          );
        },
      );
    },
  );
}

ListTile delApps(BuildContext context) {
  return ListTile(
    title: Text(
      'Delete All Applications',
    ),
    onTap: () {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              'Delete All Applications',
              style: TextStyle(
                fontSize: appBarTitle,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              'Would you like to delete all applications? This cannot be undone.',
              textAlign: TextAlign.center,
            ),
            actions: [
              platformDetect(context, DeleteAllApplications),
            ],
          );
        },
      );
    },
  );
}

ListTile delJobs(BuildContext context) {
  return ListTile(
    title: Text(
      'Delete All Jobs',
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

ListTile delProfs(BuildContext context) {
  return ListTile(
    title: Text(
      'Delete All Profiles',
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
      'Select Main LaTeX',
    ),
    onTap: () async {
      await pickAndCopy('Main LaTeX');
    },
  );
}

Row platformDetect(BuildContext context, VoidCallback func) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (isDesktop()) ...[
        TextButton(
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
        TextButton(
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
