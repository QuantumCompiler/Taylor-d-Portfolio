import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reorderable List Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ReorderableListExample(),
    );
  }
}

class ReorderableListExample extends StatefulWidget {
  @override
  _ReorderableListExampleState createState() => _ReorderableListExampleState();
}

class _ReorderableListExampleState extends State<ReorderableListExample> {
  // List of items to display
  final List<String> _items = ['Item 1', 'Item 2', 'Item 3', 'Item 4', 'Item 5'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reorderable List Example'),
      ),
      body: ReorderableListView(
        children: _items
            .map((item) => ListTile(
                  key: ValueKey(item), // Each item must have a unique key
                  title: Text(item),
                  leading: Icon(Icons.drag_handle), // Icon to indicate dragging
                ))
            .toList(),
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final String item = _items.removeAt(oldIndex);
            _items.insert(newIndex, item);
          });
        },
      ),
    );
  }
}
