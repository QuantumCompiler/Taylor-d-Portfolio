import 'package:flutter/material.dart';
import '../../Globals/Globals.dart';
import '../../Profiles/ProfileContent.dart';
import '../../Utilities/ProfilesUtils.dart';

List<Widget> ProfileOptionsContent(BuildContext context, Profile profile, List<GlobalKey> keys, bool viewing) {
  List<Widget> ret = [];
  CoverLetterCard coverLetter = CoverLetterCard(profile: profile, type: ProfileContentType.coverLetter, keyList: keys, viewing: viewing);
  Row eduAndExp = Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      EducationCard(profile: profile, type: ProfileContentType.education, keyList: keys, viewing: viewing),
      Spacer(),
      ExperienceCard(profile: profile, type: ProfileContentType.experience, keyList: keys, viewing: viewing),
    ],
  );
  Row projAndSkills = Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ProjectsCard(profile: profile, type: ProfileContentType.projects, keyList: keys, viewing: viewing),
      Spacer(),
      SkillsCard(profile: profile, type: ProfileContentType.skills, keyList: keys, viewing: viewing),
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
  final bool viewing;
  const CoverLetterCard({
    super.key,
    required this.profile,
    required this.type,
    required this.keyList,
    required this.viewing,
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
                  viewing: widget.viewing,
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
                        widget.profile.newProfile
                            ? 'New Cover Letter Pitch'
                            : widget.viewing
                                ? 'View Cover Letter Pitch'
                                : 'Edit Cover Letter Pitch',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.035,
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
                    Center(
                      child: Text(
                        widget.profile.newProfile
                            ? 'Enter details for why you think you would be a good candidate.'
                            : widget.viewing
                                ? 'View details for why you said you would be a good candidate.'
                                : 'Edit your cover letter pitch for your profile.',
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

class EducationCard extends StatefulWidget {
  final Profile profile;
  final ProfileContentType type;
  final List<GlobalKey> keyList;
  final bool viewing;
  const EducationCard({
    super.key,
    required this.profile,
    required this.type,
    required this.keyList,
    required this.viewing,
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
                context,
                MaterialPageRoute(
                    builder: (context) => ProfileContentPage(
                          profile: widget.profile,
                          title: 'Education Entries',
                          type: ProfileContentType.education,
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
                        widget.profile.newProfile
                            ? 'New Education Entries'
                            : widget.viewing
                                ? 'View Education Entries'
                                : 'Edit Education Entries',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.06,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Icon(
                        Icons.school,
                        size: constraints.maxHeight * 0.40,
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Text(
                        widget.profile.newProfile
                            ? 'Enter details pertaining to your education.'
                            : widget.viewing
                                ? 'View you education details for your profile.'
                                : 'Edit your education details for your profile.',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.040),
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
  final bool viewing;
  const ExperienceCard({
    super.key,
    required this.profile,
    required this.type,
    required this.keyList,
    required this.viewing,
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
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ProfileContentPage(
                          profile: widget.profile,
                          title: 'Experience Entries',
                          type: ProfileContentType.experience,
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
                        widget.profile.newProfile
                            ? 'New Experience Entries'
                            : widget.viewing
                                ? 'View Experience Entries'
                                : 'Edit Experience Entries',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.06,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Icon(
                        Icons.work,
                        size: constraints.maxHeight * 0.40,
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Text(
                        widget.profile.newProfile
                            ? 'Enter details pertaining to your experience.'
                            : widget.viewing
                                ? 'View your experience details for your profile.'
                                : 'Edit your experience details for your profile.',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.040),
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
  final bool viewing;
  const ProjectsCard({
    super.key,
    required this.profile,
    required this.type,
    required this.keyList,
    required this.viewing,
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
                context,
                MaterialPageRoute(
                    builder: (context) => ProfileContentPage(
                          profile: widget.profile,
                          title: 'Project Entries',
                          type: ProfileContentType.projects,
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
                        widget.profile.newProfile
                            ? 'New Project Entries'
                            : widget.viewing
                                ? 'View Project Entries'
                                : 'Edit Project Entries',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.06,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Icon(
                        Icons.assignment,
                        size: constraints.maxHeight * 0.40,
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Text(
                        widget.profile.newProfile
                            ? 'Enter the projects that you have worked on.'
                            : widget.viewing
                                ? 'View the projects for your profile.'
                                : 'Edit the projects for your profile.',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.040),
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
  final bool viewing;
  const SkillsCard({
    super.key,
    required this.profile,
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
                    builder: (context) => ProfileContentPage(
                          profile: widget.profile,
                          title: 'Skill Entries',
                          type: ProfileContentType.skills,
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
                        widget.profile.newProfile
                            ? 'New Skills Entries'
                            : widget.viewing
                                ? 'View Skill Entires'
                                : 'Edit Skills Entries',
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
                        size: constraints.maxHeight * 0.40,
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Text(
                        widget.profile.newProfile
                            ? 'Enter the skills that you posses.'
                            : widget.viewing
                                ? 'View the skills for your profile.'
                                : 'Edit the skills for your profile.',
                        style: TextStyle(fontSize: constraints.maxWidth * 0.040),
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
