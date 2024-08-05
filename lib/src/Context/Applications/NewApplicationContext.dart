import 'package:flutter/material.dart';
import '../Globals/GlobalContext.dart';
import '../../Applications/Applications.dart';
import '../../Dashboard/Dashboard.dart';
// import '../../Applications/SaveNewApplication.dart';
import '../../Globals/ApplicationsGlobals.dart';
import '../../Globals/Globals.dart';
import '../../Jobs/Jobs.dart';
import '../../Profiles/Profiles.dart';
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
          NavToPage(context, 'Jobs', Icon(Icons.work), JobsPage(), true, false),
          NavToPage(context, 'Profiles', Icon(Icons.person), ProfilePage(), true, false),
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
          RecCard(title: 'Cover Letter About Applicant', content: app.recommendations[0], cardController: app.aboutMeCont, height: 0.5, width: 0.8, cardLines: 7),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(title: 'Cover Letter Recommendation For Job', content: app.recommendations[1], cardController: app.whyJobCont, height: 0.5, width: 0.8, cardLines: 7),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(title: 'Cover Letter Recommendation For Applicant', content: app.recommendations[2], cardController: app.whyMeCont, height: 0.5, width: 0.8, cardLines: 7),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(title: 'Education Recommendations For Applicant', content: app.recommendations[3], cardController: app.eduRecCont, height: 0.4, width: 0.8, cardLines: 3),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(title: 'Experience Recommendations For Applicant', content: app.recommendations[4], cardController: app.expRecCont, height: 0.4, width: 0.8, cardLines: 3),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(title: 'Framework Recommendations For Applicant', content: app.recommendations[5], cardController: app.framRecCont, height: 0.4, width: 0.8, cardLines: 3),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(title: 'Math Skills Recommendations For Applicant', content: app.recommendations[6], cardController: app.mathSkillsRecCont, height: 0.4, width: 0.8, cardLines: 3),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(title: 'Personal Skills Recommendations For Applicant', content: app.recommendations[7], cardController: app.persSkillsRecCont, height: 0.4, width: 0.8, cardLines: 3),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(title: 'Programming Languages Recommendations For Applicant', content: app.recommendations[8], cardController: app.progLangRecCont, height: 0.4, width: 0.8, cardLines: 3),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(title: 'Programming Skills Recommendations For Applicant', content: app.recommendations[9], cardController: app.progSkillsRecCont, height: 0.4, width: 0.8, cardLines: 3),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(title: 'Project Recommendations For Applicant', content: app.recommendations[10], cardController: app.projRecCont, height: 0.4, width: 0.8, cardLines: 3),
          SizedBox(height: standardSizedBoxHeight),
          RecCard(title: 'Scientific Skills Recommendations For Applicant', content: app.recommendations[11], cardController: app.sciRecCont, height: 0.4, width: 0.8, cardLines: 3),
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
            // Map<String, dynamic> recs = await GetOpenAIRecs(context, app, openAIModel);
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
  return BottomAppBar(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: Text('Compile Portfolio'),
          onPressed: () async {
            await app.SetFinalFiles();
            // updateState();
            // print(app.aboutMeCont.text);
            // print(app.whyJobCont.text);
            // print(app.whyMeCont.text);
            // print(app.eduRecCont.text);
            // print(app.expRecCont.text);
            // print(app.framRecCont.text);
            // print(app.mathSkillsRecCont.text);
            // print(app.persSkillsRecCont.text);
            // print(app.progLangRecCont.text);
            // print(app.progSkillsRecCont.text);
            // print(app.projRecCont.text);
            // print(app.sciRecCont.text);
          },
        ),
      ],
    ),
  );
}

class RecCard extends StatefulWidget {
  final String title;
  String content;
  TextEditingController cardController;
  final double height;
  final double width;
  final int cardLines;
  RecCard({
    super.key,
    required this.title,
    required this.content,
    required this.cardController,
    required this.height,
    required this.width,
    required this.cardLines,
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

  @override
  void initState() {
    super.initState();
    widget.cardController.text = widget.content;
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
          onTap: () {},
          child: Container(
            width: MediaQuery.of(context).size.width * widget.width,
            height: MediaQuery.of(context).size.height * widget.height,
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
                          fontSize: secondaryTitles,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: standardSizedBoxHeight),
                    TextField(
                      controller: widget.cardController,
                      maxLines: widget.cardLines,
                    )
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
