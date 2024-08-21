import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../Profiles/ViewProfile.dart';
import '../../Jobs/ViewJob.dart';
import '../../Applications/ViewApplication.dart';
import '../../Utilities/GlobalUtils.dart';
import '../../Applications/Applications.dart';
import '../../Context/Globals/GlobalContext.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Settings/Settings.dart';
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

class ViewApplicationContent extends StatefulWidget {
  final Application app;

  const ViewApplicationContent({super.key, required this.app});

  @override
  _ViewApplicationContentState createState() => _ViewApplicationContentState();
}

class _ViewApplicationContentState extends State<ViewApplicationContent> {
  late Future<List<File>> _filesFuture;

  @override
  void initState() {
    super.initState();
    _filesFuture = _loadFiles();
  }

  Future<List<File>> _loadFiles() async {
    await widget.app.GetRecs();
    await widget.app.LoadApplication();
    return [
      widget.app.aboutMeFile,
      widget.app.whyJobFile,
      widget.app.whyMeFile,
      widget.app.eduRecFile,
      widget.app.expRecFile,
      widget.app.frameRecFile,
      widget.app.mathSkillsRecFile,
      widget.app.persSkillsRecFile,
      widget.app.progLangRecFile,
      widget.app.progSkillsRecFile,
      widget.app.projRecFile,
      widget.app.sciRecFile,
    ];
  }

  bool coverLetterChecked = false;
  bool portfolioChecked = false;
  bool resumeChecked = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<File>>(
      future: _filesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading files'));
        } else {
          final files = snapshot.data!;
          return SingleChildScrollView(
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: standardSizedBoxHeight),
                  Center(
                    child: Text(
                      'Documents Created',
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
                      CoverLetterCard(app: widget.app),
                      PortfolioCard(app: widget.app),
                      ResumeCard(app: widget.app),
                    ],
                  ),
                  SizedBox(height: standardSizedBoxHeight),
                  Center(
                    child: Text(
                      'Job And Profile',
                      style: TextStyle(
                        fontSize: secondaryTitles,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: standardSizedBoxHeight),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Tooltip(
                          message: 'Click To View Job Used',
                          child: ListTile(
                            title: Text(widget.app.jobUsed.name),
                            onTap: () async {
                              Navigator.of(context).pushAndRemoveUntil(RightToLeftPageRoute(page: ViewJobPage(app: widget.app, jobName: widget.app.jobUsed.name)), (Route<dynamic> route) => false);
                            },
                          ),
                        ),
                        Tooltip(
                          message: 'Click To View Profile Used',
                          child: ListTile(
                            title: Text(widget.app.profileUsed.name),
                            onTap: () async {
                              Navigator.of(context)
                                  .pushAndRemoveUntil(RightToLeftPageRoute(page: ViewProfilePage(app: widget.app, profileName: widget.app.profileUsed.name)), (Route<dynamic> route) => false);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: standardSizedBoxHeight),
                  Center(
                    child: Text(
                      'Application Files',
                      style: TextStyle(
                        fontSize: secondaryTitles,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: standardSizedBoxHeight),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Tooltip(
                          message: 'Click To Download Cover Letter',
                          child: ListTile(
                            title: Text('Cover Letter'),
                            trailing: Checkbox(
                              value: coverLetterChecked,
                              onChanged: (value) {
                                setState(() {
                                  coverLetterChecked = value!;
                                });
                              },
                            ),
                            onTap: () async {
                              await SaveFile(context, widget.app.coverLetterPDF.path);
                            },
                          ),
                        ),
                        Tooltip(
                          message: 'Click To Download Portfolio',
                          child: ListTile(
                            title: Text('Portfolio'),
                            trailing: Checkbox(
                              value: portfolioChecked,
                              onChanged: (value) {
                                setState(() {
                                  portfolioChecked = value!;
                                });
                              },
                            ),
                            onTap: () async {
                              await SaveFile(context, widget.app.portfolioPDF.path);
                            },
                          ),
                        ),
                        Tooltip(
                          message: 'Click To Download Resume',
                          child: ListTile(
                            title: Text('Resume'),
                            trailing: Checkbox(
                              value: resumeChecked,
                              onChanged: (value) {
                                setState(() {
                                  resumeChecked = value!;
                                });
                              },
                            ),
                            onTap: () async {
                              await SaveFile(context, widget.app.resumePDF.path);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: standardSizedBoxHeight),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        child: Text('Clear Selections'),
                        onPressed: () => {
                          setState(() {
                            coverLetterChecked = false;
                            portfolioChecked = false;
                            resumeChecked = false;
                          }),
                        },
                      ),
                      SizedBox(width: standardSizedBoxWidth),
                      ElevatedButton(
                        child: Text('Download Files'),
                        onPressed: () async {
                          await SaveFiles(context, widget.app, coverLetterChecked, portfolioChecked, resumeChecked);
                          setState(() {
                            coverLetterChecked = false;
                            portfolioChecked = false;
                            resumeChecked = false;
                          });
                        },
                      ),
                      SizedBox(width: standardSizedBoxWidth),
                      ElevatedButton(
                        child: Text('Select All'),
                        onPressed: () => {
                          setState(() {
                            coverLetterChecked = true;
                            portfolioChecked = true;
                            resumeChecked = true;
                          }),
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: standardSizedBoxHeight),
                  Center(
                    child: Text(
                      'OpenAI Recommendations',
                      style: TextStyle(
                        fontSize: secondaryTitles,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: standardSizedBoxHeight),
                  RecCard(app: widget.app, file: files[0], title: 'About Applicant'),
                  RecCard(app: widget.app, file: files[1], title: 'Why The Job'),
                  RecCard(app: widget.app, file: files[2], title: 'Why You'),
                  RecCard(app: widget.app, file: files[3], title: 'Education Recommendations'),
                  RecCard(app: widget.app, file: files[4], title: 'Experience Recommendations'),
                  RecCard(app: widget.app, file: files[5], title: 'Framework Recommendations'),
                  RecCard(app: widget.app, file: files[6], title: 'Math Skill Recommendations'),
                  RecCard(app: widget.app, file: files[7], title: 'Personal Skill Recommendations'),
                  RecCard(app: widget.app, file: files[8], title: 'Programming Language Recommendations'),
                  RecCard(app: widget.app, file: files[9], title: 'Programming Skill Recommendations'),
                  RecCard(app: widget.app, file: files[10], title: 'Projects Recommendations'),
                  RecCard(app: widget.app, file: files[11], title: 'Scientific Skill Recommendations'),
                ],
              ),
            ),
          );
        }
      },
    );
  }
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
            await PDFPage(context, widget.app, 'Cover Letter.pdf');
          },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.25,
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

class PortfolioCard extends StatefulWidget {
  final Application app;
  const PortfolioCard({
    super.key,
    required this.app,
  });

  @override
  _PortfolioCardState createState() => _PortfolioCardState();
}

class _PortfolioCardState extends State<PortfolioCard> {
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
            await PDFPage(context, widget.app, 'Portfolio.pdf');
          },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.25,
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
                        'View Generated Portfolio',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.06,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Icon(
                        Icons.file_present,
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

class RecCard extends StatefulWidget {
  final Application app;
  final File file;
  final String title;
  const RecCard({
    super.key,
    required this.app,
    required this.file,
    required this.title,
  });

  @override
  _RecCardState createState() => _RecCardState();
}

class _RecCardState extends State<RecCard> {
  bool _isHovered = false;

  void _updateHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }

  String convertCont() {
    try {
      if (widget.file.existsSync()) {
        return widget.file.readAsStringSync();
      } else {
        return 'File not found';
      }
    } catch (e) {
      return 'Error reading file: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).cardTheme;
    String content = convertCont();
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
                    Text(content),
                    SizedBox(height: standardSizedBoxHeight),
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

class ResumeCard extends StatefulWidget {
  final Application app;
  const ResumeCard({
    super.key,
    required this.app,
  });

  @override
  _ResumeCardState createState() => _ResumeCardState();
}

class _ResumeCardState extends State<ResumeCard> {
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
            await PDFPage(context, widget.app, 'Resume.pdf');
          },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.25,
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
                        'View Generated Resume',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.06,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Icon(
                        Icons.description,
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

class PDFScreen extends StatelessWidget {
  final Application prevApp;
  final File pdfFile;
  const PDFScreen({
    super.key,
    required this.prevApp,
    required this.pdfFile,
  });

  @override
  Widget build(BuildContext context) {
    String pdfName = pdfFile.path.split('/').last;
    pdfName = pdfName.replaceAll('.pdf', '').trim();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${prevApp.name} - $pdfName',
          style: TextStyle(
            fontSize: appBarTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined),
          onPressed: () async {
            Navigator.of(context).pushAndRemoveUntil(
              LeftToRightPageRoute(page: ViewApplicationPage(app: prevApp)),
              (Route<dynamic> route) => false,
            );
          },
        ),
        actions: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NavToPage(context, 'Settings', Icon(Icons.settings), SettingsPage(), true, false),
              NavToPage(context, 'Dashboard', Icon(Icons.dashboard), Dashboard(), true, false),
            ],
          ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: Future(() => pdfFile.exists()),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.data == true) {
              return SfPdfViewer.file(pdfFile);
            } else {
              return Center(child: Text('File not found: ${pdfFile.path}'));
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Download File'),
              onPressed: () async {
                await SaveFile(context, pdfFile.path);
              },
            ),
            SizedBox(width: standardSizedBoxWidth),
            ElevatedButton(
              child: Text('View Externally'),
              onPressed: () async {
                await OpenFile(pdfFile.path);
              },
            ),
          ],
        ),
      ),
    );
  }
}
