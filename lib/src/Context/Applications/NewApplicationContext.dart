import 'package:flutter/material.dart';
import '../Globals/GlobalContext.dart';
import '../../Applications/Applications.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Globals/ApplicationsGlobals.dart';
import '../../Globals/Globals.dart';
import '../../Settings/Settings.dart';
import '../../Utilities/ApplicationsUtils.dart';

AppBar NewApplicationAppBar(BuildContext context) {
  return AppBar(
    title: Text(
      'New Application',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    ),
    leading: NavToPage(context, 'Applications', Icon(Icons.arrow_back_ios_new_outlined), ApplicationsPage(), false, true),
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

SingleChildScrollView NewApplicationContent(BuildContext context, Application app, Function updateState) {
  String openAIModel = gpt_4o;
  return SingleChildScrollView(
    child: Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 4 * standardSizedBoxHeight),
          DropdownMenu(
            dropdownMenuEntries: openAIEntries,
            enableFilter: true,
            width: MediaQuery.of(context).size.width * 0.4,
            menuHeight: MediaQuery.of(context).size.height * 0.4,
            helperText: 'Select Model For OpenAI',
            onSelected: (value) {
              openAIModel = value.toString();
              app.openAIModel = openAIModel;
            },
          ),
        ],
      ),
    ),
  );
}

SingleChildScrollView NewApplicationRecsContent(BuildContext context, Application app, Function updateState) {
  return SingleChildScrollView(
    child: Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: standardSizedBoxHeight),
          Text(
            'OpenAI Recommendations',
            style: TextStyle(
              fontSize: appBarTitle,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(app: app, title: 'Cover Letter About Applicant', content: app.recommendations[0]),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(app: app, title: 'Cover Letter Recommendation For Job', content: app.recommendations[1]),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(app: app, title: 'Cover Letter Recommendation For Applicant', content: app.recommendations[2]),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(app: app, title: 'Education Recommendations For Applicant', content: app.recommendations[3]),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(app: app, title: 'Experience Recommendations', content: app.recommendations[4]),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(app: app, title: 'Framework Recommendations', content: app.recommendations[5]),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(app: app, title: 'Math Skill Recommendations', content: app.recommendations[6]),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(app: app, title: 'Personal Skill Recommendations', content: app.recommendations[7]),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(app: app, title: 'Programming Language Recommendations', content: app.recommendations[8]),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(app: app, title: 'Programming Skill Recommendations', content: app.recommendations[9]),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(app: app, title: 'Project Recommendations', content: app.recommendations[10]),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(app: app, title: 'Scientific Skill Recommendations', content: app.recommendations[11]),
        ],
      ),
    ),
  );
}

BottomAppBar NewApplicationBottomAppBar(BuildContext context, Application app, Function updateState) {
  return BottomAppBar(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: Text('Get Recommendations'),
          onPressed: () async {
            // Map<String, dynamic> recs = await GetOpenAIRecs(context, app, app.openAIModel);
            Map<String, dynamic> recs = testOpenAIResults;
            List<String> finRecs = await StringifyRecs(recs, app);
            app.SetRecs(recs, finRecs);
            updateState();
          },
        ),
      ],
    ),
  );
}

BottomAppBar NewApplicationCompileBottomAppBar(BuildContext context, Application app, Function updateState) {
  TextEditingController nameController = TextEditingController();
  return BottomAppBar(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: Text('Compile Portfolio'),
          onPressed: () async {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return NewApplicationDialog(context, app, nameController);
              },
            );
          },
        ),
      ],
    ),
  );
}

class RecCard extends StatefulWidget {
  final Application app;
  final String title;
  final String content;
  const RecCard({
    super.key,
    required this.app,
    required this.title,
    required this.content,
  });

  @override
  _RecCardState createState() => _RecCardState();
}

class _RecCardState extends State<RecCard> {
  bool _isHovered = false;
  late TextEditingController cont;

  void _updateHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }

  @override
  void initState() {
    super.initState();
    cont = TextEditingController(text: widget.content);
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
          onTap: () async {},
          child: Container(
            width: MediaQuery.of(context).size.width * 0.75,
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
                          fontSize: constraints.maxWidth * 0.03,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: standardSizedBoxHeight),
                    TextFormField(
                      controller: cont,
                      minLines: 1,
                      maxLines: 100,
                    ),
                    SizedBox(height: standardSizedBoxHeight),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Tooltip(
                          message: 'Click To Clear Content',
                          child: IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              cont.clear();
                            },
                          ),
                        ),
                        SizedBox(width: standardSizedBoxWidth),
                        Tooltip(
                          message: 'Click To Reset Content',
                          child: IconButton(
                            icon: Icon(Icons.restore_outlined),
                            onPressed: () {
                              cont.text = widget.content;
                            },
                          ),
                        ),
                      ],
                    ),
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

// class RecCard extends StatefulWidget {
//   final String title;
//   String content;
//   TextEditingController cardController;
//   final double height;
//   final double width;
//   final int cardLines;
//   RecCard({
//     super.key,
//     required this.title,
//     required this.content,
//     required this.cardController,
//     required this.height,
//     required this.width,
//     required this.cardLines,
//   });

//   @override
//   _RecCardState createState() => _RecCardState();
// }

// class _RecCardState extends State<RecCard> {
//   bool _isHovered = false;
//   void _updateHover(bool isHovered) {
//     setState(() {
//       _isHovered = isHovered;
//     });
//   }

//   @override
//   void initState() {
//     super.initState();
//     widget.cardController.text = widget.content;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cardTheme = Theme.of(context).cardTheme;
//     return MouseRegion(
//       onEnter: (event) => _updateHover(true),
//       onExit: (event) => _updateHover(false),
//       child: Card(
//         elevation: _isHovered ? 80.0 : cardTheme.elevation,
//         shadowColor: _isHovered ? cardHoverColor : cardTheme.shadowColor,
//         child: InkWell(
//           onTap: () {},
//           child: Container(
//             width: MediaQuery.of(context).size.width * widget.width,
//             height: MediaQuery.of(context).size.height * widget.height,
//             margin: EdgeInsets.all(15.0),
//             child: LayoutBuilder(
//               builder: (context, constraints) {
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   children: [
//                     Center(
//                       child: Text(
//                         widget.title,
//                         style: TextStyle(
//                           fontSize: secondaryTitles,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: standardSizedBoxHeight),
//                     TextField(
//                       controller: widget.cardController,
//                       maxLines: widget.cardLines,
//                     )
//                   ],
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
