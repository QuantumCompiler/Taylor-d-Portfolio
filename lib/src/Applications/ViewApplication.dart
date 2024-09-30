import 'package:flutter/material.dart';
import '../Context/Applications/ViewApplicationContext.dart';
import '../Context/Globals/GlobalContext.dart';
import '../Utilities/ApplicationsUtils.dart';

class ViewApplicationPage extends StatefulWidget {
  Application app;
  ViewApplicationPage({
    super.key,
    required this.app,
  });
  @override
  ViewApplicationPageState createState() => ViewApplicationPageState();
}

class ViewApplicationPageState extends State<ViewApplicationPage> {
  @override
  void initState() {
    super.initState();
    widget.app.LoadApplication();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ViewApplicationAppBar(context, widget.app),
      body: ViewApplicationContent(app: widget.app),
      bottomNavigationBar: BottomNav(context),
    );
  }
}
