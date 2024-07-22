import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Clickable Card Example')),
        body: Center(
          child: ClickableCard(),
        ),
      ),
    );
  }
}

class ClickableCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 40.0,
      child: InkWell(
        onTap: () {
          // Add your onTap code here
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Card tapped!')),
          );
        },
        child: Container(
          width: 300,
          height: 150,
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Card Title',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'This is a description of the card.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
