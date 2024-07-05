import 'package:flutter/material.dart';
import '../Context/SaveNewApplicationContext.dart';
import '../Utilities/ApplicationsUtils.dart';

class SaveNewApplicationPage extends StatefulWidget {
  final Map<String, dynamic> openAIContent;
  final ApplicationContent content;
  const SaveNewApplicationPage({
    super.key,
    required this.openAIContent,
    required this.content,
  });
  @override
  SaveNewApplicationPageState createState() => SaveNewApplicationPageState();
}

class SaveNewApplicationPageState extends State<SaveNewApplicationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context, setState),
      body: loadContent(context, widget.content, widget.openAIContent, setState),
    );
  }
}
