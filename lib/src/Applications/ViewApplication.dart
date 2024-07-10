import 'package:flutter/material.dart';
import '../Context/Applications/ViewApplicationContext.dart';
import '../Utilities/ApplicationsUtils.dart';

class ViewAppPage extends StatelessWidget {
  final Application prevApp;
  const ViewAppPage({
    required this.prevApp,
  });
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: prevApp.LoadAppData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(
                title: Text('Error'),
              ),
              body: Center(
                child: Text('Error loading application data: ${snapshot.error}'),
              ),
            );
          }
          return Scaffold(
            appBar: appBar(context, prevApp),
            body: loadAppContent(context, prevApp),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text('Loading'),
            ),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}
