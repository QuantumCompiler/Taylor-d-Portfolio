import 'package:flutter/material.dart';
import '../Globals/GlobalContext.dart';
import '../../Applications/Applications.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Globals/Globals.dart';
import '../../Jobs/Jobs.dart';
import '../../Profiles/EditProfile.dart';
import '../../Profiles/NewProfile.dart';
import '../../Profiles/ProfileContent.dart';
import '../../Settings/Settings.dart';
import '../../Utilities/GlobalUtils.dart';
import '../../Utilities/ProfilesUtils.dart';

AppBar ProfileAppBar(BuildContext context, List<Profile> profiles) {
  return AppBar(
    title: Text(
      profiles.isNotEmpty ? 'Profiles, Edit Or Create New' : 'Profiles, Create New Profile',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    leading: NavToPage(context, 'Dashboard', Icon(Icons.arrow_back_ios_new_outlined), Dashboard(), false, false),
    actions: [
      Row(
        children: [
          NavToPage(context, 'Applications', Icon(Icons.task), ApplicationsPage(), true, false),
          NavToPage(context, 'Jobs', Icon(Icons.work), JobsPage(), true, false),
          NavToPage(context, 'Settings', Icon(Icons.settings), SettingsPage(), true, false),
          NavToPage(context, 'Dashboard', Icon(Icons.dashboard), Dashboard(), true, false),
        ],
      ),
    ],
  );
}

SingleChildScrollView ProfileContent(BuildContext context, List<Profile> profiles, Function setState) {
  return SingleChildScrollView(
    child: profiles.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: standardSizedBoxHeight),
              Center(
                child: Text(
                  'View / Edit Previous Profiles',
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
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      return Tooltip(
                        message: 'Click To Edit ${profiles[index].name}',
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: ListTile(
                            title: Text(profiles[index].name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: 'Delete Profile ${profiles[index].name}',
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      size: 30.0,
                                    ),
                                    onPressed: () async {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return DeleteProfileDialog(context, profiles, index, setState);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: EditProfilePage(profileName: profiles[index].name)), (Route<dynamic> route) => false);
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
                  message: 'Create A New Profile',
                  child: IconButton(
                    icon: Icon(Icons.add_circle_outline_rounded),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: NewProfilePage()), (Route<dynamic> route) => false);
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
                  'No Current Profiles',
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
                  message: 'Create A New Profile',
                  child: IconButton(
                    icon: Icon(Icons.add_circle_outline_rounded),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: NewProfilePage()), (Route<dynamic> route) => false);
                    },
                  ),
                ),
              ),
            ],
          ),
  );
}

List<Widget> ProfileOptionsContent(BuildContext context, Profile profile, List<GlobalKey> keys) {
  List<Widget> ret = [];
  CoverLetterCard coverLetter = CoverLetterCard(profile: profile, type: ProfileContentType.coverLetter, keyList: keys);
  Row eduAndExp = Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      EducationCard(profile: profile, type: ProfileContentType.education, keyList: keys),
      Spacer(),
      ExperienceCard(profile: profile, type: ProfileContentType.experience, keyList: keys),
    ],
  );
  Row projAndSkills = Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ProjectsCard(profile: profile, type: ProfileContentType.projects, keyList: keys),
      Spacer(),
      SkillsCard(profile: profile, type: ProfileContentType.skills, keyList: keys),
    ],
  );
  ret.add(coverLetter);
  ret.add(eduAndExp);
  ret.add(projAndSkills);
  return ret;
}

class CoverLetterCard extends StatefulWidget {
  final Profile profile;
  final ProfileContentType type;
  final List<GlobalKey> keyList;
  const CoverLetterCard({
    super.key,
    required this.profile,
    required this.type,
    required this.keyList,
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
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileContentPage(
                  profile: widget.profile,
                  title: 'Cover Letter Pitch',
                  type: ProfileContentType.coverLetter,
                  keyList: widget.keyList,
                ),
              ),
            );
          },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
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
                        widget.profile.newProfile ? 'New Cover Letter Pitch' : 'Cover Letter Pitch - ${widget.profile.name}',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.02,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Icon(
                        Icons.draw_outlined,
                        size: constraints.maxHeight * 0.30,
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Text(
                        widget.profile.newProfile ? 'Enter details for why you think you would be a good candidate.' : 'Edit your cover letter pitch for - ${widget.profile.name}',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.012),
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

class EducationCard extends StatefulWidget {
  final Profile profile;
  final ProfileContentType type;
  final List<GlobalKey> keyList;
  const EducationCard({
    super.key,
    required this.profile,
    required this.type,
    required this.keyList,
  });

  @override
  _EducationCardState createState() => _EducationCardState();
}

class _EducationCardState extends State<EducationCard> {
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
                context, MaterialPageRoute(builder: (context) => ProfileContentPage(profile: widget.profile, title: 'Education Entries', type: ProfileContentType.education, keyList: widget.keyList)));
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
                        widget.profile.newProfile ? 'Education Entries' : 'Education Entries - ${widget.profile.name}',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Icon(
                        Icons.school,
                        size: constraints.maxHeight * 0.30,
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Text(
                        widget.profile.newProfile ? 'Enter details pertaining to your education.' : 'Edit your education details for - ${widget.profile.name}',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.025),
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

class ExperienceCard extends StatefulWidget {
  final Profile profile;
  final ProfileContentType type;
  final List<GlobalKey> keyList;
  const ExperienceCard({
    super.key,
    required this.profile,
    required this.type,
    required this.keyList,
  });

  @override
  _ExperienceCardState createState() => _ExperienceCardState();
}

class _ExperienceCardState extends State<ExperienceCard> {
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
            await Navigator.push(context,
                MaterialPageRoute(builder: (context) => ProfileContentPage(profile: widget.profile, title: 'Experience Entries', type: ProfileContentType.experience, keyList: widget.keyList)));
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
                        widget.profile.newProfile ? 'Experience Entries' : 'Experience Entries - ${widget.profile.name}',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Icon(
                        Icons.work,
                        size: constraints.maxHeight * 0.30,
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Text(
                        widget.profile.newProfile ? 'Enter details pertaining to your experience.' : 'Edit your experience details for - ${widget.profile.name}',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.025),
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

class ProjectsCard extends StatefulWidget {
  final Profile profile;
  final ProfileContentType type;
  final List<GlobalKey> keyList;
  const ProjectsCard({
    super.key,
    required this.profile,
    required this.type,
    required this.keyList,
  });

  @override
  _ProjectsCardState createState() => _ProjectsCardState();
}

class _ProjectsCardState extends State<ProjectsCard> {
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
                context, MaterialPageRoute(builder: (context) => ProfileContentPage(profile: widget.profile, title: 'Project Entries', type: ProfileContentType.projects, keyList: widget.keyList)));
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
                        widget.profile.newProfile ? 'Project Entries' : 'Project Entries - ${widget.profile.name}',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Icon(
                        Icons.assignment,
                        size: constraints.maxHeight * 0.30,
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Text(
                        widget.profile.newProfile ? 'Enter the projects that you have worked on.' : 'Edit the projects for - ${widget.profile.name}',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.025),
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
  final Profile profile;
  final ProfileContentType type;
  final List<GlobalKey> keyList;
  const SkillsCard({
    super.key,
    required this.profile,
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
                context, MaterialPageRoute(builder: (context) => ProfileContentPage(profile: widget.profile, title: 'Skill Entries', type: ProfileContentType.skills, keyList: widget.keyList)));
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
                        widget.profile.newProfile ? 'Skills Entries' : 'Skills Entries - ${widget.profile.name}',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.04,
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
                        widget.profile.newProfile ? 'Enter the skills that you posses.' : 'Edit the skills for - ${widget.profile.name}',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.025),
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
