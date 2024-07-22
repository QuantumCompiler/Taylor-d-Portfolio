import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Define a shortcut for Cmd + S
  final Map<LogicalKeySet, Intent> _shortcuts = {
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS): ActivateIntent(),
  };

  // Define an action for the shortcut
  final Map<Type, Action<Intent>> _actions = {
    ActivateIntent: CallbackAction<ActivateIntent>(
      onInvoke: (intent) => _handleCmdS(),
    ),
  };

  static void _handleCmdS() {
    print('Cmd + S is pressed');
    // Perform your action here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cmd + S Listener Example'),
      ),
      body: Shortcuts(
        shortcuts: _shortcuts,
        child: Actions(
          actions: _actions,
          child: Focus(
            autofocus: true,
            child: Center(
              child: Text('Focus and press Cmd + S'),
            ),
          ),
        ),
      ),
    );
  }
}
