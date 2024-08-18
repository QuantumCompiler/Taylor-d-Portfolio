import 'package:flutter/material.dart';
import '../../Applications/Applications.dart';
import '../../Context/Globals/GlobalContext.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Settings/Settings.dart';
import '../../Utilities/GlobalUtils.dart';
import '../../Utilities/ApplicationsUtils.dart';
import '../../Globals/Globals.dart';

AppBar ViewApplicationAppBar(BuildContext context, Application app) {
  return AppBar(
    title: Text(
      app.name,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_outlined),
      onPressed: () {
        Navigator.pushAndRemoveUntil(
            context,
            LeftToRightPageRoute(
              page: ApplicationsPage(),
            ),
            (Route<dynamic> route) => false);
      },
    ),
    actions: [
      Row(
        children: [
          NavToPage(context, 'Settings', Icon(Icons.settings), SettingsPage(), true, false),
          NavToPage(context, 'Dashboard', Icon(Icons.dashboard), Dashboard(), true, false),
        ],
      ),
    ],
  );
}

SingleChildScrollView ViewApplicationContent(BuildContext context, Application app) {
  return SingleChildScrollView(
    child: Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: standardSizedBoxHeight),
          Center(
            child: Text(
              'Documents Created:',
              style: TextStyle(
                fontSize: secondaryTitles,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: standardSizedBoxHeight),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CoverLetterCard(app: app),
            ],
          )
        ],
      ),
    ),
  );
}

class CoverLetterCard extends StatefulWidget {
  final Application app;
  const CoverLetterCard({
    super.key,
    required this.app,
  });

  @override
  _CoverLetterCardState createState() => _CoverLetterCardState();
}

class _CoverLetterCardState extends State<CoverLetterCard> {
  bool _isHovered = false;

  void _updateHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
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
        child: InkWell(
          onTap: () async {
            print(widget.app.name);
            print(widget.app.jobUsed.name);
            print(widget.app.profileUsed.name);
          },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.3,
            height: MediaQuery.of(context).size.height * 0.20,
            margin: EdgeInsets.all(15.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'View Generated Cover Letter',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.06,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Icon(
                        Icons.draw_outlined,
                        size: constraints.maxHeight * 0.40,
                      ),
                    ),
                    Spacer(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}


// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// class PDFScreen extends StatelessWidget {
//   final Application prevApp;
//   const PDFScreen({super.key, required this.prevApp});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios_new_outlined),
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//         ),
//       ),
//       body: FutureBuilder<String>(
//         future: prevApp.retrievePDFDir('Resume', 'main.pdf'),
//         builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
//           if (snapshot.connectionState == ConnectionState.done) {
//             if (snapshot.hasError) {
//               return Center(child: Text('Error: ${snapshot.error}'));
//             } else {
//               final pdfFilePath = snapshot.data!;
//               final file = File(pdfFilePath);
//               if (file.existsSync()) {
//                 return SfPdfViewer.file(file);
//               } else {
//                 return Center(child: Text('File not found: $pdfFilePath'));
//               }
//             }
//           } else {
//             return Center(child: CircularProgressIndicator());
//           }
//         },
//       ),
//     );
//   }
// }

// AppBar appBar(BuildContext context, Application prevApp) {
//   return AppBar(
//     leading: IconButton(
//       icon: Icon(Icons.arrow_back_ios_new_outlined),
//       onPressed: () {
//         Navigator.of(context).pop();
//       },
//     ),
//     actions: <Widget>[
//       IconButton(
//         icon: Icon(Icons.dashboard),
//         onPressed: () {
//           if (isDesktop()) {
//             Navigator.of(context).pop();
//             Navigator.of(context).pop();
//             Navigator.of(context).pop();
//             Navigator.of(context).pop();
//           } else if (isMobile()) {
//             Navigator.of(context).pop();
//             Navigator.of(context).pop();
//             Navigator.of(context).pop();
//             Navigator.of(context).pop();
//             Navigator.of(context).pop();
//           }
//         },
//       )
//     ],
//     title: Text(
//       prevApp.applicationName,
//       style: TextStyle(
//         fontSize: appBarTitle,
//         fontWeight: FontWeight.bold,
//       ),
//     ),
//   );
// }

// SingleChildScrollView loadAppContent(BuildContext context, Application prevApp) {
//   return SingleChildScrollView(
//     child: Center(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: <Widget>[
//           SizedBox(height: standardSizedBoxHeight),
//           recCont(context, 'Education Recommendations', prevApp.eduRecFile.readAsStringSync()),
//           recCont(context, 'Experience Recommendations', prevApp.expRecFile.readAsStringSync()),
//           recCont(context, 'Project Recommendations', prevApp.projRecFile.readAsStringSync()),
//           recCont(context, 'Math Skills Recommendations', prevApp.mathRecFile.readAsStringSync()),
//           recCont(context, 'Personal Skills Recommendations', prevApp.persRecFile.readAsStringSync()),
//           recCont(context, 'Framework Recommendations', prevApp.framRecFile.readAsStringSync()),
//           recCont(context, 'Programming Languages Recommendations', prevApp.langRecFile.readAsStringSync()),
//           recCont(context, 'Programming Skills Recommendations', prevApp.progRecFile.readAsStringSync()),
//           recCont(context, 'Scientific Skills Recommendations', prevApp.sciRecFile.readAsStringSync()),
//         ],
//       ),
//     ),
//   );
// }

// BottomAppBar bottomAppBar(BuildContext context, Application prevApp) {
//   return BottomAppBar(
//     child: Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: <Widget>[
//         ElevatedButton(
//           child: Text(
//             'View Portfolio',
//           ),
//           onPressed: () {
//             Navigator.push(context, MaterialPageRoute(builder: (context) => PDFScreen(prevApp: prevApp)));
//           },
//         ),
//       ],
//     ),
//   );
// }

// Center recCont(BuildContext context, String title, String content) {
//   return Center(
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       mainAxisAlignment: MainAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: secondaryTitles,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         SizedBox(height: standardSizedBoxHeight),
//         Container(
//           width: MediaQuery.of(context).size.width * 0.75,
//           child: Text(content),
//         ),
//         SizedBox(height: standardSizedBoxHeight),
//       ],
//     ),
//   );
// }
