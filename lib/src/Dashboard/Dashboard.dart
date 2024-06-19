import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.15,
        child: Drawer(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0),
            child: Column(
              children: <Widget>[
                GestureDetector(
                  onTap: () => {},
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Tooltip(
                      message: 'Dashboard',
                      child: Icon(
                        Icons.dashboard,
                      ),
                    ),
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Tooltip(
                      message: 'Profile',
                      child: Icon(
                        Icons.person,
                      ),
                    ),
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Tooltip(
                      message: 'Settings',
                      child: Icon(
                        Icons.settings,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.1, right: MediaQuery.of(context).size.width * 0.1),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  ResumeCard(),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                  CoverLetterCard(),
                ],
              ),
            ],
          ),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Center(
                child: Text(
                  '123',
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Center(
                child: Text(
                  '123',
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
