import 'package:flutter/material.dart';
import '../Context/Applications/ViewApplicationContext.dart';
import '../Utilities/ApplicationsUtils.dart';

class ViewApplicationPage extends StatefulWidget {
  final Application app;
  const ViewApplicationPage({
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
    );
  }
}

// import 'package:flutter/material.dart';
// import '../Context/Applications/ViewApplicationContext.dart';
// import '../Utilities/ApplicationsUtils.dart';

// class ViewAppPage extends StatelessWidget {
//   final Application prevApp;
//   const ViewAppPage({
//     super.key,
//     required this.prevApp,
//   });
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<void>(
//       future: prevApp.LoadAppData(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.done) {
//           if (snapshot.hasError) {
//             return Scaffold(
//               appBar: AppBar(
//                 title: Text('Error'),
//               ),
//               body: Center(
//                 child: Text('Error loading application data: ${snapshot.error}'),
//               ),
//             );
//           }
//           return Scaffold(
//             appBar: appBar(context, prevApp),
//             body: loadAppContent(context, prevApp),
//             bottomNavigationBar: bottomAppBar(context, prevApp),
//           );
//         } else {
//           return Scaffold(
//             appBar: AppBar(
//               title: Text('Loading'),
//             ),
//             body: Center(
//               child: CircularProgressIndicator(),
//             ),
//           );
//         }
//       },
//     );
//   }
// }
