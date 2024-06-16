import 'package:flutter/material.dart';
import 'GenResume.dart';
import 'GenCoverLetter.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar is the topmost part of the screen
      appBar: AppBar(),
      // Drawer for application navigation
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.15,
        child: Drawer(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Icon(Icons.home), // Home Icon
                Icon(Icons.settings), // Settings Icon
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        // Padding for the content
        padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.1, right: MediaQuery.of(context).size.width * 0.1),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  // Resumes Generated Card
                  ResumeCard(),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                  // Cover Letters Generated Card
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
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.width * 0.1, maxHeight: MediaQuery.of(context).size.height * 0.25, minWidth: MediaQuery.of(context).size.width * 0.25, maxWidth: MediaQuery.of(context).size.width * 0.35),
      child: Card(
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
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
              SizedBox(
                width: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/genresume');
                  },
                  child: Text('Generate Resume'),
                ),
              ),
            ])),
      ),
    );
  }
}

class CoverLetterCard extends StatelessWidget {
  const CoverLetterCard({super.key});
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.width * 0.1, maxHeight: MediaQuery.of(context).size.height * 0.25, minWidth: MediaQuery.of(context).size.width * 0.25, maxWidth: MediaQuery.of(context).size.width * 0.35),
      child: Card(
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
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
              SizedBox(
                width: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/gencoverletter');
                  },
                  child: Text('Generate Cover Letter'),
                ),
              ),
            ])),
      ),
    );
  }
}
