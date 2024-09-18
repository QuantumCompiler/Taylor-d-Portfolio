import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool infoOpen = false;

  TextEditingController urlCont = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filesFuture = _loadFiles();
    widget.app.LoadApplication();
    urlCont.text = widget.app.appURL;
  }

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
                  SizedBox(height: standardSizedBoxHeight),
                  Center(
                    child: Text(
                      'Application Contents',
                      style: TextStyle(
                        fontSize: secondaryTitles,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: standardSizedBoxHeight),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: ExpansionTile(
                      title: Text('Application Information'),
                      initiallyExpanded: false,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.70,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: standardSizedBoxHeight),
                              ExpansionTile(
                                title: Text('Application Content'),
                                children: [
                                  SizedBox(height: standardSizedBoxHeight),
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.60,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ListTile(
                                          title: Text(widget.app.jobUsed.name),
                                          onTap: () async {
                                            Navigator.of(context)
                                                .pushAndRemoveUntil(RightToLeftPageRoute(page: ViewJobPage(app: widget.app, jobName: widget.app.jobUsed.name)), (Route<dynamic> route) => false);
                                          },
                                        ),
                                        ListTile(
                                          title: Text(widget.app.profileUsed.name),
                                          onTap: () async {
                                            Navigator.of(context).pushAndRemoveUntil(
                                                RightToLeftPageRoute(page: ViewProfilePage(app: widget.app, profileName: widget.app.profileUsed.name)), (Route<dynamic> route) => false);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: standardSizedBoxHeight),
                                ],
                              ),
                              ExpansionTile(
                                title: Text('Application Files'),
                                children: [
                                  SizedBox(height: standardSizedBoxHeight),
                                  Text(
                                    'Application Files',
                                    style: TextStyle(
                                      fontSize: secondaryTitles,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: standardSizedBoxHeight),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context).size.width * 0.65,
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              ListTile(
                                                title: Text('Cover Letter'),
                                                trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(Icons.download),
                                                      onPressed: () async {
                                                        String path = widget.app.coverLetterPDF.path;
                                                        await SaveFile(context, path);
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.view_carousel),
                                                      onPressed: () async {
                                                        String path = widget.app.coverLetterPDF.path;
                                                        await OpenFile(path);
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.open_in_new),
                                                      onPressed: () async {
                                                        String path = widget.app.coverLetterPDF.path;
                                                        OpenFileDir(path);
                                                      },
                                                    ),
                                                    Checkbox(
                                                      value: coverLetterChecked,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          coverLetterChecked = value!;
                                                        });
                                                      },
                                                    )
                                                  ],
                                                ),
                                              ),
                                              ListTile(
                                                title: Text('Portfolio'),
                                                trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(Icons.download),
                                                      onPressed: () async {
                                                        String path = widget.app.portfolioPDF.path;
                                                        await SaveFile(context, path);
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.view_carousel),
                                                      onPressed: () async {
                                                        String path = widget.app.portfolioPDF.path;
                                                        await OpenFile(path);
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.open_in_new),
                                                      onPressed: () async {
                                                        String path = widget.app.portfolioPDF.path;
                                                        OpenFileDir(path);
                                                      },
                                                    ),
                                                    Checkbox(
                                                      value: portfolioChecked,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          portfolioChecked = value!;
                                                        });
                                                      },
                                                    )
                                                  ],
                                                ),
                                              ),
                                              ListTile(
                                                title: Text('Resume'),
                                                trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(Icons.download),
                                                      onPressed: () async {
                                                        String path = widget.app.resumePDF.path;
                                                        await SaveFile(context, path);
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.view_carousel),
                                                      onPressed: () async {
                                                        String path = widget.app.resumePDF.path;
                                                        await OpenFile(path);
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.open_in_new),
                                                      onPressed: () async {
                                                        String path = widget.app.resumePDF.path;
                                                        OpenFileDir(path);
                                                      },
                                                    ),
                                                    Checkbox(
                                                      value: resumeChecked,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          resumeChecked = value!;
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              ListTile(
                                                title: Text('LaTeX Files'),
                                                trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(Icons.open_in_new),
                                                      onPressed: () async {
                                                        final masterDir = await GetAppDir();
                                                        Directory appsDir = Directory('${masterDir.path}/Applications');
                                                        Directory currDir = Directory('${appsDir.path}/${widget.app.name}');
                                                        Directory latexDir = Directory('${currDir.path}/LaTeX Documents');
                                                        OpenFileDir(latexDir.path);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: standardSizedBoxHeight),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  TextButton(
                                                    child: Text('Select / Unselect All'),
                                                    onPressed: () => {
                                                      setState(() {
                                                        if (coverLetterChecked || portfolioChecked || resumeChecked) {
                                                          coverLetterChecked = false;
                                                          portfolioChecked = false;
                                                          resumeChecked = false;
                                                        } else {
                                                          coverLetterChecked = true;
                                                          portfolioChecked = true;
                                                          resumeChecked = true;
                                                        }
                                                      }),
                                                    },
                                                  ),
                                                  SizedBox(width: standardSizedBoxWidth),
                                                  TextButton(
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
                                                  TextButton(
                                                    child: Text('Open LaTeX Files'),
                                                    onPressed: () async {
                                                      String path = widget.app.resumePDF.parent.parent.path;
                                                      path += '/LaTeX Documents';
                                                      OpenFileDir(path);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: standardSizedBoxHeight),
                                ],
                              ),
                              ExpansionTile(
                                title: Text('Application Logistics'),
                                children: [
                                  SizedBox(height: standardSizedBoxHeight),
                                  Text(
                                    'Application Logistics',
                                    style: TextStyle(
                                      fontSize: secondaryTitles,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: standardSizedBoxHeight),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Applied?'),
                                      // Applied
                                      Checkbox(
                                        value: widget.app.applied,
                                        onChanged: (value) async {
                                          setState(() {
                                            widget.app.SetApplied(value!);
                                          });
                                          await widget.app.SetAdditional();
                                        },
                                      ),
                                      // Interviewed
                                      SizedBox(width: standardSizedBoxWidth),
                                      Text('Interview?'),
                                      Checkbox(
                                        value: widget.app.interview,
                                        onChanged: (value) async {
                                          setState(() {
                                            widget.app.SetInterview(value!);
                                          });
                                          await widget.app.SetAdditional();
                                        },
                                      ),
                                      // Offer
                                      SizedBox(width: standardSizedBoxWidth),
                                      Text('Offer?'),
                                      Checkbox(
                                        value: widget.app.offer,
                                        onChanged: (value) async {
                                          setState(() {
                                            widget.app.SetOffer(value!);
                                          });
                                          await widget.app.SetAdditional();
                                        },
                                      ),
                                      // Application Date
                                      SizedBox(width: standardSizedBoxWidth),
                                      Text('Application Date:'),
                                      widget.app.appDate != null ? Text(' ${widget.app.appDate?.month}/${widget.app.appDate?.day}/${widget.app.appDate?.year}') : Text(''),
                                      IconButton(
                                        icon: Icon(Icons.date_range),
                                        onPressed: () async {
                                          DateTime? date = await SelectDate(context, initialDate: widget.app.appDate ?? DateTime.now());
                                          setState(() {
                                            widget.app.SetDate(date);
                                          });
                                          await widget.app.SetAdditional();
                                        },
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: standardSizedBoxHeight),
                                  InkWell(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: secondaryTitles,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Application URL:',
                                          ),
                                          if (widget.app.appURL != "")
                                            TextSpan(
                                              text: ' Link',
                                              style: TextStyle(
                                                color: Colors.blue,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    onTap: () async {
                                      if (widget.app.appURL != "") {
                                        await launchUrl(Uri.parse(widget.app.appURL));
                                      }
                                    },
                                  ),
                                  SizedBox(height: standardSizedBoxHeight),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.55,
                                        ),
                                        child: TextFormField(
                                          controller: urlCont,
                                          minLines: 1,
                                          maxLines: 1,
                                          decoration: InputDecoration(hintText: 'Enter url for the application...'),
                                          onChanged: (value) async {
                                            setState(() {
                                              widget.app.SetURL(value);
                                            });
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.save),
                                        onPressed: () async {
                                          setState(() {
                                            widget.app.SetURL(urlCont.text);
                                          });
                                          await widget.app.SetAdditional();
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.view_kanban),
                                        onPressed: () async {
                                          await launchUrl(Uri.parse(widget.app.appURL));
                                        },
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: standardSizedBoxHeight),
                                ],
                              ),
                              SizedBox(height: standardSizedBoxHeight),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ExpansionTile(
                          title: Text('Recommendations'),
                          initiallyExpanded: false,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.70,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: standardSizedBoxHeight),
                                  ExpansionTile(
                                    title: Text('About You'),
                                    children: [
                                      SizedBox(height: standardSizedBoxHeight),
                                      RecCard(app: widget.app, file: files[0], title: 'About You'),
                                      SizedBox(height: standardSizedBoxHeight),
                                    ],
                                  ),
                                  ExpansionTile(
                                    title: Text('Education'),
                                    children: [
                                      SizedBox(height: standardSizedBoxHeight),
                                      RecCard(app: widget.app, file: files[3], title: 'Education Recommendations'),
                                      SizedBox(height: standardSizedBoxHeight),
                                    ],
                                  ),
                                  ExpansionTile(
                                    title: Text('Experience'),
                                    children: [
                                      SizedBox(height: standardSizedBoxHeight),
                                      RecCard(app: widget.app, file: files[4], title: 'Experience Recommendations'),
                                      SizedBox(height: standardSizedBoxHeight),
                                    ],
                                  ),
                                  ExpansionTile(
                                    title: Text('Frameworks'),
                                    children: [
                                      SizedBox(height: standardSizedBoxHeight),
                                      RecCard(app: widget.app, file: files[5], title: 'Framework Recommendations'),
                                      SizedBox(height: standardSizedBoxHeight),
                                    ],
                                  ),
                                  ExpansionTile(
                                    title: Text('Math Skills'),
                                    children: [
                                      SizedBox(height: standardSizedBoxHeight),
                                      RecCard(app: widget.app, file: files[6], title: 'Math Skill Recommendations'),
                                      SizedBox(height: standardSizedBoxHeight),
                                    ],
                                  ),
                                  ExpansionTile(
                                    title: Text('Personal Skills'),
                                    children: [
                                      SizedBox(height: standardSizedBoxHeight),
                                      RecCard(app: widget.app, file: files[7], title: 'Personal Skill Recommendations'),
                                      SizedBox(height: standardSizedBoxHeight),
                                    ],
                                  ),
                                  ExpansionTile(
                                    title: Text('Programming Languages'),
                                    children: [
                                      SizedBox(height: standardSizedBoxHeight),
                                      RecCard(app: widget.app, file: files[8], title: 'Programming Language Recommendations'),
                                      SizedBox(height: standardSizedBoxHeight),
                                    ],
                                  ),
                                  ExpansionTile(
                                    title: Text('Programming Skills'),
                                    children: [
                                      SizedBox(height: standardSizedBoxHeight),
                                      RecCard(app: widget.app, file: files[9], title: 'Programming Skill Recommendations'),
                                      SizedBox(height: standardSizedBoxHeight),
                                    ],
                                  ),
                                  ExpansionTile(
                                    title: Text('Projects'),
                                    children: [
                                      SizedBox(height: standardSizedBoxHeight),
                                      RecCard(app: widget.app, file: files[10], title: 'Project Recommendations'),
                                      SizedBox(height: standardSizedBoxHeight),
                                    ],
                                  ),
                                  ExpansionTile(
                                    title: Text('Scientific Skills'),
                                    children: [
                                      SizedBox(height: standardSizedBoxHeight),
                                      RecCard(app: widget.app, file: files[11], title: 'Scientific Skill Recommendations'),
                                      SizedBox(height: standardSizedBoxHeight),
                                    ],
                                  ),
                                  ExpansionTile(
                                    title: Text('Why You'),
                                    children: [
                                      SizedBox(height: standardSizedBoxHeight),
                                      RecCard(app: widget.app, file: files[2], title: 'Why You'),
                                      SizedBox(height: standardSizedBoxHeight),
                                    ],
                                  ),
                                  ExpansionTile(
                                    title: Text('Why The Job'),
                                    children: [
                                      SizedBox(height: standardSizedBoxHeight),
                                      RecCard(app: widget.app, file: files[1], title: 'Why The Job'),
                                      SizedBox(height: standardSizedBoxHeight),
                                    ],
                                  ),
                                  SizedBox(height: standardSizedBoxHeight),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          heroTag: 'Open CV Dir',
                          onPressed: () async {
                            String path = widget.app.coverLetterPDF.path;
                            OpenFileDir(path);
                          },
                          child: Icon(Icons.file_open),
                        ),
                        SizedBox(width: standardSizedBoxWidth),
                        FloatingActionButton(
                          heroTag: 'Download CV File',
                          onPressed: () async {
                            String path = widget.app.coverLetterPDF.path;
                            await SaveFile(context, path);
                          },
                          child: Icon(Icons.download),
                        ),
                      ],
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          heroTag: 'Open Portfolio Dir',
                          onPressed: () async {
                            String path = widget.app.portfolioPDF.path;
                            OpenFileDir(path);
                          },
                          child: Icon(Icons.file_open),
                        ),
                        SizedBox(width: standardSizedBoxWidth),
                        FloatingActionButton(
                          heroTag: 'Download Portfolio PDF',
                          onPressed: () async {
                            String path = widget.app.portfolioPDF.path;
                            await SaveFile(context, path);
                          },
                          child: Icon(Icons.download),
                        ),
                      ],
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          heroTag: 'Open Resume Dir',
                          onPressed: () async {
                            String path = widget.app.resumePDF.path;
                            OpenFileDir(path);
                          },
                          child: Icon(Icons.file_open),
                        ),
                        SizedBox(width: standardSizedBoxWidth),
                        FloatingActionButton(
                          heroTag: 'Download Resume PDF',
                          onPressed: () async {
                            String path = widget.app.resumePDF.path;
                            await SaveFile(context, path);
                          },
                          child: Icon(Icons.download),
                        ),
                      ],
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
            TextButton(
              child: Text('Download File'),
              onPressed: () async {
                await SaveFile(context, pdfFile.path);
              },
            ),
            SizedBox(width: standardSizedBoxWidth),
            TextButton(
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
