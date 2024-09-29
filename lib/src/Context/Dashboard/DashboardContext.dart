// Imports
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
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
          width: MediaQuery.of(context).size.width * (isDesktop() ? 0.25 : 0.2),
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
                        fontSize: constraints.maxWidth * (isDesktop() ? 0.08 : 0.125),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: standardSizedBoxHeight),
                  Center(
                    child: Icon(
                      widget.icon.icon,
                      size: constraints.maxWidth * (isDesktop() ? 0.15 : 0.3),
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

class LargeDisplayCard extends StatefulWidget {
  final String title;
  Widget child;
  LargeDisplayCard({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  _LargeDisplayCardState createState() => _LargeDisplayCardState();
}

class _LargeDisplayCardState extends State<LargeDisplayCard> {
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
          width: MediaQuery.of(context).size.width * 0.8,
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
                        fontSize: constraints.maxWidth * (isDesktop() ? 0.04 : 0.055),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: standardSizedBoxHeight),
                  widget.child,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class PDFChart extends StatefulWidget {
  @override
  _PDFChartState createState() => _PDFChartState();
}

class _PDFChartState extends State<PDFChart> {
  int _coverLetCount = 0;
  int _portfolioCount = 0;
  int _resumeCount = 0;
  int _applicationCount = 0;

  List<_ChartData> data = [];

  @override
  void initState() {
    super.initState();
    _countFiles();
  }

  void _countFiles() async {
    String coverLet = 'Cover Letter.pdf';
    String portfolio = 'Portfolio.pdf';
    String resume = 'Resume.pdf';
    String apps = 'Applications';

    int coverLetCount = await CountAllPDFs(coverLet);
    int portfolioCount = await CountAllPDFs(portfolio);
    int resumeCount = await CountAllPDFs(resume);
    int applicationCount = await CountSubdirectories(apps);

    setState(() {
      _coverLetCount = coverLetCount;
      _portfolioCount = portfolioCount;
      _resumeCount = resumeCount;
      _applicationCount = applicationCount;

      data = [
        _ChartData('Cover Letters', _coverLetCount.toDouble()),
        _ChartData('Portfolios', _portfolioCount.toDouble()),
        _ChartData('Resumes', _resumeCount.toDouble()),
        _ChartData('Applications', _applicationCount.toDouble()),
      ];
    });
  }

  TooltipBehavior _tooltipBehavior = TooltipBehavior(enable: true);
  int _tappedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return data.isEmpty
        ? Container()
        : SfCircularChart(
            tooltipBehavior: _tooltipBehavior,
            title: ChartTitle(
              text: 'PDF Documents',
              textStyle: TextStyle(
                fontSize: secondaryTitles,
                fontWeight: FontWeight.bold,
              ),
              alignment: ChartAlignment.center,
            ),
            series: <CircularSeries<_ChartData, String>>[
              DoughnutSeries<_ChartData, String>(
                dataSource: data,
                xValueMapper: (_ChartData data, _) => data.x,
                yValueMapper: (_ChartData data, _) => data.y,
                name: 'Documents',
                explode: true,
                explodeIndex: _tappedIndex,
                strokeColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : customWhite,
                explodeOffset: '30%',
                dataLabelSettings: DataLabelSettings(isVisible: true),
                pointColorMapper: (_ChartData data, _) {
                  return Theme.of(context).brightness == Brightness.dark ? customWhite : Colors.black;
                },
                onPointTap: (ChartPointDetails details) {
                  setState(() {
                    _tappedIndex = details.pointIndex!;
                  });
                },
              )
            ],
          );
  }
}

class ContentChart extends StatefulWidget {
  @override
  _ContentChartState createState() => _ContentChartState();
}

class _ContentChartState extends State<ContentChart> {
  int _appsCount = 0;
  int _jobsCount = 0;
  int _profilesCount = 0;

  List<_ChartData> data = [];

  @override
  void initState() {
    super.initState();
    _countContent();
  }

  void _countContent() async {
    int appsCount = await CountSubdirectories('Applications');
    int jobsCount = await CountSubdirectories('Jobs');
    int profilesCount = await CountSubdirectories('Profiles');
    setState(() {
      _appsCount = appsCount;
      _jobsCount = jobsCount;
      _profilesCount = profilesCount;

      data = [
        _ChartData('Applications', _appsCount.toDouble()),
        _ChartData('Jobs', _jobsCount.toDouble()),
        _ChartData('Profiles', _profilesCount.toDouble()),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return data.isEmpty
        ? Container()
        : SfCartesianChart(
            primaryXAxis: CategoryAxis(),
            primaryYAxis: NumericAxis(minimum: 0, maximum: max(_appsCount, max(_jobsCount, _profilesCount)) * 1.1, interval: 20),
            tooltipBehavior: TooltipBehavior(enable: true),
            isTransposed: true,
            title: ChartTitle(
              text: 'User Content',
              textStyle: TextStyle(
                fontSize: secondaryTitles,
                fontWeight: FontWeight.bold,
              ),
              alignment: ChartAlignment.center,
            ),
            series: <CartesianSeries<_ChartData, String>>[
              BarSeries<_ChartData, String>(
                dataSource: data,
                xValueMapper: (_ChartData data, _) => data.x,
                yValueMapper: (_ChartData data, _) => data.y,
                name: 'Current Count',
                color: Theme.of(context).brightness == Brightness.dark ? customWhite : Colors.black,
                borderColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : customWhite,
              )
            ],
          );
  }
}

class _ChartData {
  _ChartData(this.x, this.y);
  final String x;
  final double y;
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
        isDesktop()
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Spacer(),
                  PDFChart(),
                  Spacer(),
                  ContentChart(),
                  Spacer(),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PDFChart(),
                  SizedBox(height: standardSizedBoxHeight),
                  ContentChart(),
                ],
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
          tooltip: applicationToolTip,
          onPressed: () {
            Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: ApplicationsPage()), (Route<dynamic> route) => false);
          },
          icon: Icon(Icons.task),
        ),
        Spacer(),
        IconButton(
          onPressed: () => {},
          icon: Icon(Icons.dashboard),
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
