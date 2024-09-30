// Imports
import 'package:flutter/material.dart';
import '../Context/Globals/GlobalContext.dart';
import '../Context/Dashboard/DashboardContext.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: dashBoardContent(context),
      bottomNavigationBar: BottomNav(context),
    );
  }
}
