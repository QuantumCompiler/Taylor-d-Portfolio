import 'package:flutter/material.dart';
import '../Utilities/ApplicationsUtils.dart';
import '../Context/Applications/NewApplicationContext.dart';
// import '../Utilities/ApplicationsUtils.dart';
// import '../Utilities/JobUtils.dart';
// import '../Utilities/ProfilesUtils.dart';

class NewApplicationPage extends StatefulWidget {
  final Application newApp;
  const NewApplicationPage({
    super.key,
    required this.newApp,
  });

  @override
  NewApplicationPageState createState() => NewApplicationPageState();
}

class NewApplicationPageState extends State<NewApplicationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NewApplicationAppBar(context),
      body: NewApplicationContent(context, widget.newApp),
    );
  }
}
