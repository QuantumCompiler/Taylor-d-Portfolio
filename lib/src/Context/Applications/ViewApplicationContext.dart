import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import '../../Globals/ApplicationsGlobals.dart';
import '../../Utilities/ApplicationsUtils.dart';
import '../../Globals/Globals.dart';

class PDFScreen extends StatelessWidget {
  final Application prevApp;
  const PDFScreen({super.key, required this.prevApp});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: FutureBuilder<String>(
        future: prevApp.retrievePDFDir('Resume', 'main.pdf'),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final pdfFilePath = snapshot.data!;
              final file = File(pdfFilePath);
              if (file.existsSync()) {
                return SfPdfViewer.file(file);
              } else {
                return Center(child: Text('File not found: $pdfFilePath'));
              }
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

AppBar appBar(BuildContext context, Application prevApp) {
  return AppBar(
    leading: IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.of(context).pop();
      },
    ),
    actions: <Widget>[
      IconButton(
        icon: Icon(Icons.dashboard),
        onPressed: () {
          if (isDesktop()) {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          } else if (isMobile()) {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          }
        },
      )
    ],
    title: Text(
      prevApp.applicationName,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

SingleChildScrollView loadAppContent(BuildContext context, Application prevApp) {
  return SingleChildScrollView(
    child: Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: standardSizedBoxHeight),
          recCont(context, 'Education Recommendations', prevApp.eduRecFile.readAsStringSync()),
          recCont(context, 'Experience Recommendations', prevApp.expRecFile.readAsStringSync()),
          recCont(context, 'Project Recommendations', prevApp.projRecFile.readAsStringSync()),
          recCont(context, 'Math Skills Recommendations', prevApp.mathRecFile.readAsStringSync()),
          recCont(context, 'Personal Skills Recommendations', prevApp.persRecFile.readAsStringSync()),
          recCont(context, 'Framework Recommendations', prevApp.framRecFile.readAsStringSync()),
          recCont(context, 'Programming Languages Recommendations', prevApp.langRecFile.readAsStringSync()),
          recCont(context, 'Programming Skills Recommendations', prevApp.progRecFile.readAsStringSync()),
          recCont(context, 'Scientific Skills Recommendations', prevApp.sciRecFile.readAsStringSync()),
        ],
      ),
    ),
  );
}

BottomAppBar bottomAppBar(BuildContext context, Application prevApp) {
  return BottomAppBar(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ElevatedButton(
          child: Text(
            'View Portfolio',
          ),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PDFScreen(prevApp: prevApp)));
          },
        ),
      ],
    ),
  );
}

Center recCont(BuildContext context, String title, String content) {
  return Center(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: secondaryTitles,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: standardSizedBoxHeight),
        Container(
          width: MediaQuery.of(context).size.width * 0.75,
          child: Text(content),
        ),
        SizedBox(height: standardSizedBoxHeight),
      ],
    ),
  );
}
