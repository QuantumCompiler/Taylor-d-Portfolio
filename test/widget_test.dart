import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test Button increments counter', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MyTestWidget(),
      ),
    ));

    expect(find.text('0'), findsOneWidget);

    // Tap the '+' button and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });
}

class MyTestWidget extends StatefulWidget {
  @override
  _MyTestWidgetState createState() => _MyTestWidgetState();
}

class _MyTestWidgetState extends State<MyTestWidget> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$_counter'),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () {
            setState(() {
              _counter++;
            });
          },
        )
      ],
    );
  }
}
