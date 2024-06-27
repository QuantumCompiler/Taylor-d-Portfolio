// Imports
import 'package:flutter/material.dart';
import '../../Globals/Globals.dart';
import '../../Jobs/Job.dart';
import '../../Profile/Profile.dart';
import '../../Settings/Settings.dart';

/*  Parameters
      appBarTitle: Double for the title of the app bar
      drawerVerticalPadding: Double for the vertical padding of the drawer
      drawerWidth: Double for the width of the drawer
      singleCardMaxHeight: Double for the maximum height of a single card
      singleCardMinHeight: Double for the minimum height of a single card
      singleCardMaxWidth: Double for the maximum width of a single card
      singleCardMinWidth: Double for the minimum width of a single card
      singleCardPadding: Double for the padding of a single card
      singleCardWidthBox: Double for the width of the box between single cards
      dashboardTitle: String for the title of the dashboard
      dashboardToolTip: String for the tooltip of the dashboard
      profileToolTip: String for the tooltip of the profile
      jobsToolTip: String for the tooltip of the jobs
      settingsToolTip: String for the tooltip of the settings
*/
double drawerVerticalPadding = 25.0;
double drawerWidth = 0.15;
double singleCardMaxHeight = 0.25;
double singleCardMinHeight = 0.1;
double singleCardMaxWidth = 0.35;
double singleCardMinWidth = 0.25;
double singleCardPadding = 16.0;
double singleCardWidthBox = 0.05;
String dashboardTitle = 'Dashboard';
String dashboardToolTip = 'Dashboard';
String profileToolTip = 'Profile';
String jobsToolTip = 'Jobs';
String settingsToolTip = 'Settings';

/*  ResumeCard - Card for the Resume section of the Dashboard
      Input:
        key: Key for the Resume Card
      Algorithm:
        * Create a ConstrainedBox with the following constraints:
          * maxHeight: MediaQuery.of(context).size.height * singleCardMinWidth
          * minHeight: MediaQuery.of(context).size.width * singleCardMinHeight
          * maxWidth: MediaQuery.of(context).size.width * singleCardMaxWidth
          * minWidth: MediaQuery.of(context).size.width * singleCardMinWidth
        * Create a Card with the following children:
          * Padding with the following padding:
            * EdgeInsets.all(singleCardPadding)
          * Column with the following properties:
            * crossAxisAlignment: CrossAxisAlignment.stretch
            * mainAxisAlignment: MainAxisAlignment.spaceBetween
            * Children:
              * Center with the following children:
                * Text with the following properties:
                  * Text: resumesGenTitle
                  * Style: TextStyle with the following properties:
                    * fontSize: secondaryTitles
                    * fontWeight: FontWeight.bold
                  * TextAlign: TextAlign.center
              * Center with the following children:
                * Text with the following properties:
                  * Text: '$resumesGenerated'
                  * Style: TextStyle with the following properties:
                    * fontSize: secondaryTitles
                  * TextAlign: TextAlign.center
      Output:
          Returns a ConstrainedBox containing a Card with the Resume Card content
*/
class ResumeCard extends StatelessWidget {
  const ResumeCard({super.key});
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * singleCardMinWidth,
        minHeight: MediaQuery.of(context).size.width * singleCardMinHeight,
        maxWidth: MediaQuery.of(context).size.width * singleCardMaxWidth,
        minWidth: MediaQuery.of(context).size.width * singleCardMinWidth,
      ),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(singleCardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Center(
                child: Text(
                  resumesGenTitle,
                  style: TextStyle(
                    fontSize: secondaryTitles,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Center(
                child: Text(
                  '$resumesGenerated',
                  style: TextStyle(
                    fontSize: secondaryTitles,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*  CoverLetterCard - Card for the Cover Letter section of the Dashboard
      Input:
        key: Key for the Cover Letter Card
      Algorithm:
        * Create a ConstrainedBox with the following constraints:
          * maxHeight: MediaQuery.of(context).size.height * singleCardMaxHeight
          * minHeight: MediaQuery.of(context).size.height * singleCardMinHeight
          * maxWidth: MediaQuery.of(context).size.width * singleCardMaxWidth
          * minWidth: MediaQuery.of(context).size.width * singleCardMinWidth
        * Create a Card with the following children:
          * Padding with the following padding:
            * EdgeInsets.all(singleCardPadding)
          * Column with the following properties:
            * crossAxisAlignment: CrossAxisAlignment.stretch
            * mainAxisAlignment: MainAxisAlignment.spaceBetween
            * Children:
              * Center with the following children:
                * Text with the following properties:
                  * Text: coverLettersGenTitle
                  * Style: TextStyle with the following properties:
                    * fontSize: secondaryTitles
                    * fontWeight: FontWeight.bold
                  * TextAlign: TextAlign.center
              * Center with the following children:
                * Text with the following properties:
                  * Text: '$coverLettersGenerated'
                  * Style: TextStyle with the following properties:
                    * fontSize: secondaryTitles
                  * TextAlign: TextAlign.center
      Output:
          Returns a ConstrainedBox containing a Card with the Cover Letter Card content
*/
class CoverLetterCard extends StatelessWidget {
  const CoverLetterCard({super.key});
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * singleCardMaxHeight,
        minHeight: MediaQuery.of(context).size.height * singleCardMinHeight,
        maxWidth: MediaQuery.of(context).size.width * singleCardMaxWidth,
        minWidth: MediaQuery.of(context).size.width * singleCardMinWidth,
      ),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(singleCardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Center(
                child: Text(
                  coverLettersGenTitle,
                  style: TextStyle(
                    fontSize: secondaryTitles,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Center(
                child: Text(
                  '$coverLettersGenerated',
                  style: TextStyle(
                    fontSize: secondaryTitles,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*  appBar - App bar for the dashboard page
      Input:
        context: BuildContext of the application
      Algorithm:
          * Return an AppBar with the title of the dashboard
      Output:
          Returns an AppBar with the title of the dashboard
*/
AppBar appBar(BuildContext context) {
  return AppBar(
    title: Text(
      dashboardTitle,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/*  dashBoardContent - Column containing the Resume and Cover Letter Cards
      Input:
        context: BuildContext
      Algorithm:
        * Create a column for the rows of content
        * Create a row for the Resume and Cover Letter Cards
      Output:
          Returns a SingleChildScrollView containing the Resume and Cover Letter Cards
*/
SingleChildScrollView dashBoardContent(BuildContext context) {
  return SingleChildScrollView(
    child: Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ResumeCard(),
            SizedBox(
              width: MediaQuery.of(context).size.width * singleCardWidthBox,
            ),
            CoverLetterCard(),
          ],
        ),
      ],
    ),
  );
}

/*  desktopDrawer - Drawer for the Desktop version of the application
      Input:
        context: BuildContext of the application
      Algorithm:
        * Create a SizedBox with the width of the drawer
        * Create a Drawer with the following items:
          * Dashboard
          * Profile
          * Jobs
          * Settings
      Output:
          Returns a SizedBox containing a Drawer with the following items:
            * Dashboard
            * Profile
            * Jobs
            * Settings
*/
SizedBox desktopDrawer(BuildContext context) {
  return SizedBox(
    width: MediaQuery.of(context).size.width * drawerWidth,
    child: Drawer(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: drawerVerticalPadding),
        child: Column(
          children: <Widget>[
            IconButton(
              tooltip: dashboardToolTip,
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.dashboard),
            ),
            Spacer(),
            IconButton(
              tooltip: profileToolTip,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
              },
              icon: Icon(Icons.person),
            ),
            Spacer(),
            IconButton(
              tooltip: jobsToolTip,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => JobsPage()));
              },
              icon: Icon(Icons.task),
            ),
            Spacer(),
            IconButton(
              tooltip: settingsToolTip,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
              },
              icon: Icon(Icons.settings),
            ),
          ],
        ),
      ),
    ),
  );
}

/*  mobileNavbar - BottomAppBar for the Mobile version of the application
      Input:
        context: BuildContext of the application
      Algorithm:
        * Create a BottomAppBar with the following items:
          * Dashboard
          * Profile
          * Jobs
          * Settings
      Output:
          Returns a BottomAppBar with the following items:
            * Dashboard
            * Profile
            * Jobs
            * Settings
*/
BottomAppBar mobileNavbar(BuildContext context) {
  return BottomAppBar(
    color: Colors.transparent,
    child: Row(
      children: [
        IconButton(
          onPressed: () => {},
          icon: Icon(Icons.dashboard),
        ),
        Spacer(),
        IconButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
          },
          icon: Icon(Icons.person),
        ),
        Spacer(),
        IconButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => JobsPage()));
          },
          icon: Icon(Icons.task),
        ),
        Spacer(),
        IconButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
          },
          icon: Icon(Icons.settings),
        ),
      ],
    ),
  );
}
