import 'package:flutter/material.dart';

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
                  Expanded(child: ContentCard(title: 'Resumes Generated', value: '123', cardHeight: MediaQuery.of(context).size.height * 0.25, cardWidth: MediaQuery.of(context).size.width * 0.25)),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                  // Cover Letters Generated Card
                  Expanded(child: ContentCard(title: 'Cover Letters Generated', value: '123', cardHeight: MediaQuery.of(context).size.height * 0.25, cardWidth: MediaQuery.of(context).size.width * 0.25)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ContentCard - A custom card widget to display content 

*/
class ContentCard extends StatelessWidget {
  // Variables for the card
  final String title;
  final String value;
  final double cardHeight;
  final double cardWidth;
  // Constructor for the card
  const ContentCard({super.key, required this.title, required this.value, required this.cardHeight, required this.cardWidth});
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.width * 0.1, maxHeight: cardHeight, minWidth: MediaQuery.of(context).size.height * 0.1, maxWidth: cardWidth),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Title of the card
              Center(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              // Value of the card
              Center(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              // Button widget
              SizedBox(
                width: 50,
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text('Button Text'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
