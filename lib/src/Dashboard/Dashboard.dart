import 'package:flutter/material.dart';
import '../Globals/Globals.dart';
import '../Profile/Profile.dart';
import '../Settings/Settings.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          dashboardTitle,
          style: TextStyle(
            fontSize: appBarTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      drawer: isDesktop()
          ? SizedBox(
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
                        onPressed: () => {},
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
            )
          : null,
      body: SingleChildScrollView(
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
      ),
      bottomNavigationBar: isMobile()
          ? BottomAppBar(
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
                    onPressed: () => {},
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
            )
          : null,
    );
  }
}

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
