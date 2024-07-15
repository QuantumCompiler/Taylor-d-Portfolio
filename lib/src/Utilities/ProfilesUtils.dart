import 'dart:io';
import 'package:flutter/material.dart';
import '../Context/Globals/GlobalContext.dart';
import '../Globals/ProfilesGlobals.dart';
import '../Globals/Globals.dart';
import '../Utilities/GlobalUtils.dart';

class ProfileEduCont {
  late TextEditingController desInfo;
  late TextEditingController degInfo;
  late TextEditingController schoolInfo;
  late DateTime? startTime;
  late DateTime? endTime;
  late bool graduated;
  late String name;
  ProfileEduCont() {
    desInfo = TextEditingController();
    degInfo = TextEditingController();
    schoolInfo = TextEditingController();
    startTime = DateTime.now();
    endTime = DateTime.now();
    graduated = false;
    name = schoolInfo.text;
  }
}

// Profile Class
class Profile {
  // Directories
  final Future<Directory> appDir = GetAppDir();
  final Future<Directory> cacheDir = GetCacheDir();
  final Future<Directory> profsDir = GetProfilesDir();
  final Future<Directory> supDir = GetSupportDir();

  // Files
  late File eduFile;
  late File expFile;
  late File projFile;
  late File skiFile;

  // Main Titles & Name
  late String eduTitle;
  late String expTitle;
  late String name;
  late String projTitle;
  late String skiTitle;

  // Contents
  late String education;
  late String experience;
  late String projects;
  late String skills;

  // Lists Of Types
  List<ProfileEduCont> eduContList = [];

  // Constructor
  Profile({this.name = ''}) {
    eduTitle = educationTitle;
    expTitle = experienceTitle;
    projTitle = projectsTitle;
    skiTitle = skillsTitle;
    eduContList = eduContList;
  }

  // Create New Profile
  Future<void> CreateNewProfile(String profName) async {
    setProfName(profName);
    setProfDir();
    // setWriteNewFiles();
  }

  // Get Education Content
  Future<List<ProfileEduCont>> getEduCont() async {
    return eduContList;
  }

  // Set Education Content
  Future<void> setEduCont(List<ProfileEduCont> list) async {
    eduContList = list;
  }

  // Set Profile Name
  Future<void> setProfName(String profName) async {
    name = profName;
  }

  // Set Profile Directory
  Future<void> setProfDir() async {
    final parentDir = await profsDir;
    CreateDir(parentDir, name);
  }
}

class EducationProfileEntry extends StatefulWidget {
  final Profile newProfile;

  const EducationProfileEntry({
    super.key,
    required this.newProfile,
  });

  @override
  EducationProfileEntryState createState() => EducationProfileEntryState();
}

class EducationProfileEntryState extends State<EducationProfileEntry> {
  List<ProfileEduCont> entries = [];

  @override
  void initState() {
    super.initState();
    if (widget.newProfile.eduContList.isNotEmpty) {
      entries = widget.newProfile.eduContList;
    } else {
      entries.add(ProfileEduCont());
    }
  }

  void addEntry(int index) {
    setState(() {
      entries.insert(index + 1, ProfileEduCont());
    });
  }

  void deleteEntry(int index) {
    if (entries.length > 1) {
      setState(() {
        entries.removeAt(index);
      });
    }
  }

  List<ProfileEduCont> retrieveEntries() {
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          ...entries.asMap().entries.map(
            (entry) {
              int index = entry.key;
              ProfileEduCont entryData = entry.value;
              return buildContEntry(
                context,
                index,
                entryData,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildContEntry(
    BuildContext context,
    int index,
    ProfileEduCont entry,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: standardSizedBoxHeight),
        Center(
          child: Text(
            'Institution - ${index + 1}',
            style: TextStyle(fontSize: secondaryTitles, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: standardSizedBoxHeight),
        Container(
          width: MediaQuery.of(context).size.width * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: entry.schoolInfo,
                      keyboardType: TextInputType.multiline,
                      maxLines: 1,
                      decoration: InputDecoration(hintText: 'Enter name here...'),
                      onChanged: (value) {
                        setState(() {
                          entry.name = entry.schoolInfo.text;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: 'Graduated From Institution?',
                    child: Checkbox(
                      value: entry.graduated,
                      onChanged: (bool? value) {
                        setState(() {
                          entry.graduated = value ?? false;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: 'Select Start Date',
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        entry.startTime = await SelectDate(context);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: 'Select End Date',
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        entry.endTime = await SelectDate(context);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: standardSizedBoxHeight),
              TextFormField(
                controller: entry.degInfo,
                keyboardType: TextInputType.multiline,
                maxLines: 1,
                decoration: InputDecoration(hintText: 'Enter degree(s) information here...'),
              ),
              SizedBox(height: standardSizedBoxHeight),
              TextFormField(
                controller: entry.desInfo,
                keyboardType: TextInputType.multiline,
                maxLines: 10,
                decoration: InputDecoration(hintText: 'Enter description here...'),
              ),
              SizedBox(height: standardSizedBoxHeight),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () => addEntry(index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => deleteEntry(index),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
