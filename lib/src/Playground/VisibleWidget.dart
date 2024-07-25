import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Toggle Widget Visibility'),
        ),
        body: VisibilityToggleExample(),
      ),
    );
  }
}

class VisibilityToggleExample extends StatefulWidget {
  @override
  _VisibilityToggleExampleState createState() => _VisibilityToggleExampleState();
}

class _VisibilityToggleExampleState extends State<VisibilityToggleExample> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isVisible = !_isVisible;
              });
            },
            child: Text(_isVisible ? 'Hide' : 'Show'),
          ),
          SizedBox(height: 20),
          _isVisible
              ? Text(
                  'Hello, I am visible now!',
                  style: TextStyle(fontSize: 24),
                )
              : SizedBox(), // Use SizedBox() or Container() for invisible state
        ],
      ),
    );
  }
}
