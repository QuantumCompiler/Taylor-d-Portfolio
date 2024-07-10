import 'package:flutter/material.dart';
import '../Context/Applications/SaveNewApplicationContext.dart';
import '../Utilities/ApplicationsUtils.dart';

class SaveNewApplicationPage extends StatefulWidget {
  final Map<String, dynamic> openAIContent;
  final ApplicationContent appContent;

  const SaveNewApplicationPage({
    super.key,
    required this.openAIContent,
    required this.appContent,
  });

  @override
  SaveNewApplicationPageState createState() => SaveNewApplicationPageState();
}

class SaveNewApplicationPageState extends State<SaveNewApplicationPage> {
  late List<TextEditingController> controllers;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(9, (_) => TextEditingController());
    initializeControllers();
  }

  void initializeControllers() {
    String joinList(dynamic list) {
      return (list as List<dynamic>).map((e) => e.toString()).join(", ");
    }

    controllers[0].text = joinList(widget.openAIContent["Education_Recommendations"]);
    controllers[1].text = joinList(widget.openAIContent["Experience_Recommendations"]);
    controllers[2].text = joinList(widget.openAIContent["Projects_Recommendations"]);
    controllers[3].text = joinList(widget.openAIContent["Math_Skills_Recommendations"]);
    controllers[4].text = joinList(widget.openAIContent["Personal_Skills_Recommendations"]);
    controllers[5].text = joinList(widget.openAIContent["Framework_Recommendations"]);
    controllers[6].text = joinList(widget.openAIContent["Programming_Languages_Recommendations"]);
    controllers[7].text = joinList(widget.openAIContent["Programming_Skills_Recommendations"]);
    controllers[8].text = joinList(widget.openAIContent["Scientific_Skills_Recommendations"]);
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context, widget.appContent, setState),
      body: loadContent(context, widget.appContent, controllers, setState),
      bottomNavigationBar: bottomAppBar(context, widget.appContent, controllers),
    );
  }
}
