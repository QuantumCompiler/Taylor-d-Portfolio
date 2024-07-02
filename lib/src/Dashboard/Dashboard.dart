// Imports
import 'package:flutter/material.dart';
import '../Globals/Globals.dart';
import '../Context/DashboardContext.dart';

/*  Dashboard - Page for the Dashboard in the application
      Constructor:
        Input: key: Key
      Algorithm:
          * Build scaffold with app bar, drawer, body, and bottom navigation bar
          * Populate body with dashboard content
      Output:
          Returns a Scaffold with the Dashboard for the application
*/
class Dashboard extends StatelessWidget {
  const Dashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      drawer: isDesktop() ? desktopDrawer(context) : null,
      body: dashBoardContent(context),
      bottomNavigationBar: isMobile() ? mobileNavbar(context) : null,
    );
  }
}
