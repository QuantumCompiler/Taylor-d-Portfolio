// Imports
import 'package:flutter/material.dart';
import '../../Globals/DashboardGlobals.dart';
import '../../Globals/Globals.dart';
import '../../Applications/Applications.dart';
import '../../Settings/Settings.dart';
import '../../Utilities/GlobalUtils.dart';

class SmallDisplayCard extends StatefulWidget {
  final String title;
  final String type;
  final Icon icon;
  const SmallDisplayCard({
    super.key,
    required this.title,
    required this.type,
    required this.icon,
  });

  @override
  _SmallDisplayCardState createState() => _SmallDisplayCardState();
}

class _SmallDisplayCardState extends State<SmallDisplayCard> {
  bool _isHovered = false;
  int fileCount = 0;

  void _updateHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }

  @override
  void initState() {
    super.initState();
    _countFiles();
  }

  Future<void> _countFiles() async {
    String input = '${widget.type}.pdf';
    int count = await CountAllPDFs(input);
    setState(() {
      fileCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).cardTheme;
    return MouseRegion(
      onEnter: (event) => _updateHover(true),
      onExit: (event) => _updateHover(false),
      child: Card(
        elevation: _isHovered ? 80.0 : cardTheme.elevation,
        shadowColor: _isHovered ? cardHoverColor : cardTheme.shadowColor,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.20,
          margin: EdgeInsets.all(15.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: constraints.maxWidth * 0.075,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: standardSizedBoxHeight),
                  Center(
                    child: Icon(
                      widget.icon.icon,
                      size: constraints.maxWidth * 0.15,
                    ),
                  ),
                  SizedBox(height: standardSizedBoxHeight),
                  Center(
                    child: Text('$fileCount'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

AppBar appBar(BuildContext context) {
  return AppBar(
    title: Text(
      dashboardTitle,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

SingleChildScrollView dashBoardContent(BuildContext context) {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: standardSizedBoxHeight),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SmallDisplayCard(title: 'Cover Letters', type: 'Cover Letter', icon: Icon(Icons.drafts)),
            SmallDisplayCard(title: 'Portfolios', type: 'Portfolio', icon: Icon(Icons.work)),
            SmallDisplayCard(title: 'Resumes', type: 'Resume', icon: Icon(Icons.attach_file)),
          ],
        ),
        SizedBox(height: standardSizedBoxHeight),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [],
        ),
        SizedBox(height: standardSizedBoxHeight),
      ],
    ),
  );
}

SizedBox desktopDrawer(BuildContext context) {
  return SizedBox(
    width: MediaQuery.of(context).size.width * drawerWidth,
    child: Drawer(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: drawerVerticalPadding),
        child: Column(
          children: <Widget>[
            IconButton(
              tooltip: dashboardToolTip,
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.dashboard),
            ),
            Spacer(),
            IconButton(
              tooltip: applicationToolTip,
              onPressed: () {
                Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: ApplicationsPage()), (Route<dynamic> route) => false);
              },
              icon: Icon(Icons.task),
            ),
            Spacer(),
            IconButton(
              tooltip: settingsToolTip,
              onPressed: () {
                Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: SettingsPage()), (Route<dynamic> route) => false);
              },
              icon: Icon(Icons.settings),
            ),
          ],
        ),
      ),
    ),
  );
}

BottomAppBar mobileNavbar(BuildContext context) {
  return BottomAppBar(
    color: Colors.transparent,
    child: Row(
      children: [
        IconButton(
          onPressed: () => {},
          icon: Icon(Icons.dashboard),
        ),
        Spacer(),
        IconButton(
          tooltip: applicationToolTip,
          onPressed: () {
            Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: ApplicationsPage()), (Route<dynamic> route) => false);
          },
          icon: Icon(Icons.task),
        ),
        Spacer(),
        IconButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: SettingsPage()), (Route<dynamic> route) => false);
          },
          icon: Icon(Icons.settings),
        ),
      ],
    ),
  );
}
