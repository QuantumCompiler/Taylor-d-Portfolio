import 'package:flutter/material.dart';
import '../../Globals/Globals.dart';
import '../../Jobs/JobsContent.dart';
import '../../Utilities/JobUtils.dart';

List<Widget> JobOptionsContent(BuildContext context, Job job, List<GlobalKey> keys, bool viewing) {
  List<Widget> ret = [];
  Row desAndOtherRow = Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      DescriptionCard(job: job, type: JobContentType.description, keyList: keys, viewing: viewing),
      Spacer(),
      OtherInfoCard(job: job, type: JobContentType.other, keyList: keys, viewing: viewing),
    ],
  );
  Row roleAndSkillsRow = Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      RoleCard(job: job, type: JobContentType.description, keyList: keys, viewing: viewing),
      Spacer(),
      SkillsCard(job: job, type: JobContentType.other, keyList: keys, viewing: viewing),
    ],
  );
  ret.add(desAndOtherRow);
  ret.add(roleAndSkillsRow);
  return ret;
}

class DescriptionCard extends StatefulWidget {
  final Job job;
  final JobContentType type;
  final List<GlobalKey> keyList;
  final bool viewing;
  const DescriptionCard({
    super.key,
    required this.job,
    required this.type,
    required this.keyList,
    required this.viewing,
  });

  @override
  _DescriptionCardState createState() => _DescriptionCardState();
}

class _DescriptionCardState extends State<DescriptionCard> {
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
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => JobContentPage(
                          job: widget.job,
                          title: 'Job Description Entry',
                          type: JobContentType.description,
                          keyList: widget.keyList,
                          viewing: widget.viewing,
                        )));
          },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.35,
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
                        widget.job.newJob
                            ? 'New Job Description'
                            : widget.viewing
                                ? 'View Job Description'
                                : 'Edit Job Description',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Icon(
                        Icons.info,
                        size: constraints.maxHeight * 0.40,
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Text(
                        widget.job.newJob
                            ? 'Enter description details for the job'
                            : widget.viewing
                                ? 'View description details for the job'
                                : 'Edit your description details for the job',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.030),
                      ),
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

class OtherInfoCard extends StatefulWidget {
  final Job job;
  final JobContentType type;
  final List<GlobalKey> keyList;
  final bool viewing;
  const OtherInfoCard({
    super.key,
    required this.job,
    required this.type,
    required this.keyList,
    required this.viewing,
  });

  @override
  _OtherInfoCardState createState() => _OtherInfoCardState();
}

class _OtherInfoCardState extends State<OtherInfoCard> {
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
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => JobContentPage(
                          job: widget.job,
                          title: 'Other Information Entry',
                          type: JobContentType.other,
                          keyList: widget.keyList,
                          viewing: widget.viewing,
                        )));
          },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.35,
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
                        widget.job.newJob
                            ? 'New Other Info'
                            : widget.viewing
                                ? 'View Other Info'
                                : 'Edit Other Info',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Icon(
                        Icons.question_mark,
                        size: constraints.maxHeight * 0.40,
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Text(
                        widget.job.newJob
                            ? 'Enter other information for the job'
                            : widget.viewing
                                ? 'View other information for the job'
                                : 'Edit other information for the job',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.030),
                      ),
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

class RoleCard extends StatefulWidget {
  final Job job;
  final JobContentType type;
  final List<GlobalKey> keyList;
  final bool viewing;
  const RoleCard({
    super.key,
    required this.job,
    required this.type,
    required this.keyList,
    required this.viewing,
  });

  @override
  _RoleCardState createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard> {
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
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => JobContentPage(
                          job: widget.job,
                          title: 'Role Description Entry',
                          type: JobContentType.role,
                          keyList: widget.keyList,
                          viewing: widget.viewing,
                        )));
          },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.35,
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
                        widget.job.newJob
                            ? 'New Role Description'
                            : widget.viewing
                                ? 'View Role Description'
                                : 'Edit Role Description',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Icon(
                        Icons.assignment_ind,
                        size: constraints.maxHeight * 0.40,
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Text(
                        widget.job.newJob
                            ? 'Enter the role description for the job'
                            : widget.viewing
                                ? 'View the role description for the job'
                                : 'Edit the role description for the job',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.030),
                      ),
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

class SkillsCard extends StatefulWidget {
  final Job job;
  final JobContentType type;
  final List<GlobalKey> keyList;
  final bool viewing;
  const SkillsCard({
    super.key,
    required this.job,
    required this.type,
    required this.keyList,
    required this.viewing,
  });

  @override
  _SkillsCardState createState() => _SkillsCardState();
}

class _SkillsCardState extends State<SkillsCard> {
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
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => JobContentPage(
                          job: widget.job,
                          title: 'Skill Requirements Entry',
                          type: JobContentType.skills,
                          keyList: widget.keyList,
                          viewing: widget.viewing,
                        )));
          },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.35,
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
                        widget.job.newJob
                            ? 'New Skill Requirements'
                            : widget.viewing
                                ? 'View Skill Requirements'
                                : 'Edit Skill Requirements',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Icon(
                        Icons.hardware,
                        size: constraints.maxHeight * 0.40,
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Text(
                        widget.job.newJob ? 'Enter the skill requirements for the job' : 'Edit the skill requirements for the job',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.030),
                      ),
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
