import 'package:flutter/material.dart';
import 'Context/NewApplicationContext.dart';
import '../Globals/ApplicationsGlobals.dart';
import '../../Globals/Globals.dart';

class NewApplicationPage extends StatelessWidget {
  const NewApplicationPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: newApplicationContent(context),
    );
  }
}

