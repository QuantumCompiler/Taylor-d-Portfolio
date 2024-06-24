import 'package:flutter/material.dart';
import '../Globals/Globals.dart';
import '../Settings/Settings.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.15,
        child: Drawer(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0),
            child: Column(
              children: <Widget>[
                IconButton(
                  tooltip: 'Dashboard',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.dashboard),
                ),
                Spacer(),
                IconButton(
                  tooltip: 'Profile',
                  onPressed: () {
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
                  },
                  icon: Icon(Icons.person),
                ),
                SizedBox(height: 20),
                IconButton(
                  tooltip: 'Job Description',
                  onPressed: () => {},
                  icon: Icon(Icons.task),
                ),
                Spacer(),
                IconButton(
                  tooltip: 'Settings',
                  onPressed: () {
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
                  },
                  icon: Icon(Icons.settings),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ResumeCard(),
                SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                CoverLetterCard(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ResumeCard extends StatelessWidget {
  const ResumeCard({super.key});
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.width * 0.1,
          maxHeight: MediaQuery.of(context).size.height * 0.25,
          minWidth: MediaQuery.of(context).size.width * 0.25,
          maxWidth: MediaQuery.of(context).size.width * 0.35),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Center(
                child: Text(
                  'Resumes Generated',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Center(
                child: Text(
                  '$resumesGenerated',
                  style: TextStyle(fontSize: 16),
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
          minHeight: MediaQuery.of(context).size.width * 0.1,
          maxHeight: MediaQuery.of(context).size.height * 0.25,
          minWidth: MediaQuery.of(context).size.width * 0.25,
          maxWidth: MediaQuery.of(context).size.width * 0.35),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Center(
                child: Text(
                  'Cover Letters Generated',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Center(
                child: Text(
                  '$coverLettersGenerated',
                  style: TextStyle(fontSize: 16),
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
