import 'package:flutter/material.dart';
import '../Globals/GlobalContext.dart';
import '../../Applications/Applications.dart';
import '../../Globals/ApplicationsGlobals.dart';
import '../../Globals/Globals.dart';
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
  );
}

SingleChildScrollView NewApplicationContent(BuildContext context, Application app, Function updateState, bool finishedRecs) {
  String openAIModel = gpt_4o;
  return !finishedRecs
      ? SingleChildScrollView(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 4 * standardSizedBoxHeight),
                DropdownMenu(
                  dropdownMenuEntries: openAIEntries,
                  enableFilter: true,
                  width: MediaQuery.of(context).size.width * (isDesktop() ? 0.5 : 0.75),
                  menuHeight: MediaQuery.of(context).size.height * 0.4,
                  helperText: 'Select Model For OpenAI',
                  onSelected: (value) {
                    openAIModel = value.toString();
                    app.openAIModel = openAIModel;
                  },
                ),
                SizedBox(height: 4 * standardSizedBoxHeight),
                CompileButton(context, app, updateState, finishedRecs)
              ],
            ),
          ),
        )
      : SingleChildScrollView(
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
                Divider(
                  thickness: 2.0,
                  indent: MediaQuery.of(context).size.width * 0.1,
                  endIndent: MediaQuery.of(context).size.width * 0.1,
                ),
                SizedBox(height: standardSizedBoxHeight),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Text('Test'),
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ExpansionTile(
                              title: Text('Cover Letter About'),
                              children: [
                                RecCard(app: app, title: 'Cover Letter About Applicant', content: app.recommendations[0], val: 0),
                              ],
                            ),
                            ExpansionTile(
                              title: Text('Cover Letter Job Recommendations'),
                              children: [
                                RecCard(app: app, title: 'Cover Letter Recommendation For Job', content: app.recommendations[1], val: 1),
                              ],
                            ),
                            ExpansionTile(
                              title: Text('Cover Letter Pitch Recommendations'),
                              children: [
                                RecCard(app: app, title: 'Cover Letter Recommendation For Applicant', content: app.recommendations[2], val: 2),
                              ],
                            ),
                            ExpansionTile(
                              title: Text('Education Recommendations'),
                              children: [
                                RecCard(app: app, title: 'Education Recommendations For Applicant', content: app.recommendations[3], val: 3),
                              ],
                            ),
                            ExpansionTile(
                              title: Text('Experience Recommendations'),
                              children: [
                                RecCard(app: app, title: 'Experience Recommendations', content: app.recommendations[4], val: 4),
                              ],
                            ),
                            ExpansionTile(
                              title: Text('Framework Recommendations'),
                              children: [
                                RecCard(app: app, title: 'Framework Recommendations', content: app.recommendations[5], val: 5),
                              ],
                            ),
                            ExpansionTile(
                              title: Text('Math Skill Recommendations'),
                              children: [
                                RecCard(app: app, title: 'Math Skill Recommendations', content: app.recommendations[6], val: 6),
                              ],
                            ),
                            ExpansionTile(
                              title: Text('Personal Skill Recommendations'),
                              children: [
                                RecCard(app: app, title: 'Personal Skill Recommendations', content: app.recommendations[7], val: 7),
                              ],
                            ),
                            ExpansionTile(
                              title: Text('Programming Language Recommendations'),
                              children: [
                                RecCard(app: app, title: 'Programming Language Recommendations', content: app.recommendations[8], val: 8),
                              ],
                            ),
                            ExpansionTile(
                              title: Text('Programming Skill Recommendations'),
                              children: [
                                RecCard(app: app, title: 'Programming Skill Recommendations', content: app.recommendations[9], val: 9),
                              ],
                            ),
                            ExpansionTile(
                              title: Text('Project Recommendations'),
                              children: [
                                RecCard(app: app, title: 'Project Recommendations', content: app.recommendations[10], val: 10),
                              ],
                            ),
                            ExpansionTile(
                              title: Text('Scientific Skill Recommendations'),
                              children: [
                                RecCard(app: app, title: 'Scientific Skill Recommendations', content: app.recommendations[11], val: 11),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: standardSizedBoxHeight),
                CompileButton(context, app, updateState, finishedRecs),
              ],
            ),
          ),
        );
}

TextButton CompileButton(BuildContext context, Application app, Function updateState, bool finishedRecs) {
  return TextButton(
    child: Text(finishedRecs ? 'Compile Documents' : 'Get Recommendations'),
    onPressed: () async {
      if (!finishedRecs) {
        // Map<String, dynamic> recs = await GetOpenAIRecs(context, app, app.openAIModel);
        Map<String, dynamic> recs = testOpenAIResults2;
        List<String> finRecs = await StringifyRecs(recs, app);
        app.SetRecs(recs, finRecs);
        updateState();
      } else {
        TextEditingController nameController = TextEditingController();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return NewApplicationDialog(context, app, nameController);
          },
        );
      }
    },
  );
}

class RecCard extends StatefulWidget {
  final Application app;
  final String title;
  final String content;
  final int val;
  const RecCard({
    super.key,
    required this.app,
    required this.title,
    required this.content,
    required this.val,
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
    cont = TextEditingController();
    cont.text = widget.content;
    if (widget.val == 0) {
      widget.app.aboutMeCont.text = widget.content;
    } else if (widget.val == 1) {
      widget.app.whyJobCont.text = widget.content;
    } else if (widget.val == 2) {
      widget.app.whyMeCont.text = widget.content;
    } else if (widget.val == 3) {
      widget.app.eduRecCont.text = widget.content;
    } else if (widget.val == 4) {
      widget.app.expRecCont.text = widget.content;
    } else if (widget.val == 5) {
      widget.app.framRecCont.text = widget.content;
    } else if (widget.val == 6) {
      widget.app.mathSkillsRecCont.text = widget.content;
    } else if (widget.val == 7) {
      widget.app.persSkillsRecCont.text = widget.content;
    } else if (widget.val == 8) {
      widget.app.progLangRecCont.text = widget.content;
    } else if (widget.val == 9) {
      widget.app.progSkillsRecCont.text = widget.content;
    } else if (widget.val == 10) {
      widget.app.projRecCont.text = widget.content;
    } else if (widget.val == 11) {
      widget.app.sciRecCont.text = widget.content;
    }
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
          width: MediaQuery.of(context).size.width * 0.65,
          margin: EdgeInsets.all(15.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.60,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: constraints.maxWidth * (isDesktop() ? 0.03 : 0.05),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: standardSizedBoxHeight),
                      TextFormField(
                        controller: cont,
                        minLines: 1,
                        maxLines: 100,
                        onChanged: (value) {
                          if (widget.val == 0) {
                            widget.app.aboutMeCont.text = cont.text;
                          } else if (widget.val == 1) {
                            widget.app.whyJobCont.text = cont.text;
                          } else if (widget.val == 2) {
                            widget.app.whyMeCont.text = cont.text;
                          } else if (widget.val == 3) {
                            widget.app.eduRecCont.text = cont.text;
                          } else if (widget.val == 4) {
                            widget.app.expRecCont.text = cont.text;
                          } else if (widget.val == 5) {
                            widget.app.framRecCont.text = cont.text;
                          } else if (widget.val == 6) {
                            widget.app.mathSkillsRecCont.text = cont.text;
                          } else if (widget.val == 7) {
                            widget.app.persSkillsRecCont.text = cont.text;
                          } else if (widget.val == 8) {
                            widget.app.progLangRecCont.text = cont.text;
                          } else if (widget.val == 9) {
                            widget.app.progSkillsRecCont.text = cont.text;
                          } else if (widget.val == 10) {
                            widget.app.projRecCont.text = cont.text;
                          } else if (widget.val == 11) {
                            widget.app.sciRecCont.text = cont.text;
                          }
                        },
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
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
