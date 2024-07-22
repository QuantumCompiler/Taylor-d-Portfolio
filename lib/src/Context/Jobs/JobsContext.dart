import 'package:flutter/material.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Globals/Globals.dart';
import '../../Jobs/EditJob.dart';
import '../../Jobs/JobsContent.dart';
import '../../Jobs/NewJob.dart';
import '../../Utilities/GlobalUtils.dart';
import '../../Utilities/JobUtils.dart';

AppBar JobsAppBar(BuildContext context, List<Job> jobs) {
  return AppBar(
    title: Text(
      jobs.isNotEmpty ? "Jobs, Edit Or Create New" : "Jobs, Create New",
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_outlined),
      onPressed: () {
        Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: Dashboard()), (Route<dynamic> route) => false);
      },
    ),
    actions: [
      Row(
        children: [
          IconButton(
            icon: Icon(Icons.dashboard),
            onPressed: () {
              Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: Dashboard()), (Route<dynamic> route) => false);
            },
          ),
        ],
      ),
    ],
  );
}

SingleChildScrollView JobContent(BuildContext context, List<Job> jobs, Function setState) {
  return SingleChildScrollView(
    child: jobs.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: standardSizedBoxHeight),
              Center(
                child: Text(
                  'View / Edit Previous Jobs',
                  style: TextStyle(
                    fontSize: secondaryTitles,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: standardSizedBoxHeight),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 0,
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * titleContainerWidth,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      return Tooltip(
                        message: 'Click To Edit ${jobs[index].name}',
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: ListTile(
                            title: Text(jobs[index].name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: 'Delete Job ${jobs[index].name}',
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      size: 30.0,
                                    ),
                                    onPressed: () async {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            content: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Delete Job ${jobs[index].name}?',
                                                  style: TextStyle(
                                                    fontSize: appBarTitle,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: standardSizedBoxHeight),
                                                Icon(
                                                  Icons.warning,
                                                  size: 50.0,
                                                ),
                                                SizedBox(height: standardSizedBoxHeight),
                                                Text(
                                                  'Are you sure that you would like to delete this job?\nThis cannot be undone.',
                                                ),
                                                SizedBox(height: standardSizedBoxHeight),
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    ElevatedButton(
                                                      child: Text(
                                                        'Cancel',
                                                      ),
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                    ),
                                                    SizedBox(width: standardSizedBoxWidth),
                                                    ElevatedButton(
                                                      child: Text('Delete'),
                                                      onPressed: () async {
                                                        try {
                                                          await DeleteJob(jobs[index].name);
                                                          setState(
                                                            () {
                                                              jobs.removeAt(index);
                                                            },
                                                          );
                                                          Navigator.of(context).pop();
                                                        } catch (e) {
                                                          throw ('Error in deleting ${jobs[index].name}');
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: EditJobPage(jobName: jobs[index].name)), (Route<dynamic> route) => false);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: standardSizedBoxHeight),
              Center(
                child: Tooltip(
                  message: 'Create New Job',
                  child: IconButton(
                    icon: Icon(Icons.add_circle_outline_rounded),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: NewJobPage()), (Route<dynamic> route) => false);
                    },
                  ),
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  'No Current Jobs',
                  style: TextStyle(
                    fontSize: secondaryTitles,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 4 * standardSizedBoxHeight),
              Center(
                child: CircularProgressIndicator(),
              ),
              SizedBox(height: 4 * standardSizedBoxHeight),
              Center(
                child: Tooltip(
                  message: 'Create A New Job',
                  child: IconButton(
                    icon: Icon(Icons.add_circle_outline_rounded),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: NewJobPage()), (Route<dynamic> route) => false);
                    },
                  ),
                ),
              ),
            ],
          ),
  );
}

List<Widget> JobOptionsContent(BuildContext context, Job job, List<GlobalKey> keys) {
  List<Widget> ret = [];
  Row desAndOtherRow = Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      DescriptionCard(job: job, type: JobContentType.description, keyList: keys),
      Spacer(),
      OtherInfoCard(job: job, type: JobContentType.other, keyList: keys),
    ],
  );
  Row roleAndSkillsRow = Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      RoleCard(job: job, type: JobContentType.description, keyList: keys),
      Spacer(),
      SkillsCard(job: job, type: JobContentType.other, keyList: keys),
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
  const DescriptionCard({
    super.key,
    required this.job,
    required this.type,
    required this.keyList,
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
                context, MaterialPageRoute(builder: (context) => JobContentPage(job: widget.job, title: 'Job Description Entry', type: JobContentType.description, keyList: widget.keyList)));
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
                        widget.job.newJob ? 'New Job Description' : 'Job Description - ${widget.job.name}',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.06,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Icon(
                        Icons.info,
                        size: constraints.maxHeight * 0.30,
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Text(
                        widget.job.newJob ? 'Enter description details for the job' : 'Edit your description details for - ${widget.job.name}',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.035),
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
  const OtherInfoCard({
    super.key,
    required this.job,
    required this.type,
    required this.keyList,
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
                context, MaterialPageRoute(builder: (context) => JobContentPage(job: widget.job, title: 'Other Information Entry', type: JobContentType.other, keyList: widget.keyList)));
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
                        widget.job.newJob ? 'New Other Info' : 'Other Info Job - ${widget.job.name}',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.06,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Icon(
                        Icons.question_mark,
                        size: constraints.maxHeight * 0.30,
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Text(
                        widget.job.newJob ? 'Enter other information for the job' : 'Edit the other information for job - ${widget.job.name}',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.035),
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
  const RoleCard({
    super.key,
    required this.job,
    required this.type,
    required this.keyList,
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
                context, MaterialPageRoute(builder: (context) => JobContentPage(job: widget.job, title: 'Role Description Entry', type: JobContentType.role, keyList: widget.keyList)));
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
                        widget.job.newJob ? 'New Role Description' : 'Role Description Job - ${widget.job.name}',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.06,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Icon(
                        Icons.assignment_ind,
                        size: constraints.maxHeight * 0.30,
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Text(
                        widget.job.newJob ? 'Enter the role description for the job' : 'Edit the role description for job - ${widget.job.name}',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.035),
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
  const SkillsCard({
    super.key,
    required this.job,
    required this.type,
    required this.keyList,
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
                context, MaterialPageRoute(builder: (context) => JobContentPage(job: widget.job, title: 'Skill Requirements Entry', type: JobContentType.skills, keyList: widget.keyList)));
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
                        widget.job.newJob ? 'New Skill Requirements' : 'Skill Requirements Job - ${widget.job.name}',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.06,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Icon(
                        Icons.hardware,
                        size: constraints.maxHeight * 0.30,
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Text(
                        widget.job.newJob ? 'Enter the skill requirements for the job' : 'Edit the skill requirements for job - ${widget.job.name}',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.035),
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
