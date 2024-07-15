import 'package:flutter/material.dart';
import '../../Context/Globals/GlobalContexts.dart';
import '../../Globals/ProfilesGlobals.dart';
import '../../Utilities/ProfilesUtils.dart';
import '../../Globals/Globals.dart';

class ContentEntries extends StatefulWidget {
  final Profile newProfile;

  ContentEntries({required this.newProfile});

  @override
  ContentEntriesState createState() => ContentEntriesState();
}

class ContentEntriesState extends State<ContentEntries> {
  List<Map<String, dynamic>> entries = [];

  @override
  void initState() {
    super.initState();
    entries.add({
      'key': GlobalKey<EduContEntryState>(),
      'nameController': TextEditingController(),
      'degreeController': TextEditingController(),
      'descriptionController': TextEditingController(),
      'graduated': false,
    });
  }

  void addEntry(int index) {
    setState(() {
      entries.insert(
        index + 1,
        {
          'key': GlobalKey<EduContEntryState>(),
          'nameController': TextEditingController(),
          'degreeController': TextEditingController(),
          'descriptionController': TextEditingController(),
          'graduated': false,
        },
      );
    });
  }

  void deleteEntry(GlobalKey<EduContEntryState> key) {
    setState(() {
      entries.removeWhere((entry) => entry['key'] == key);
    });
  }

  void updateGraduated(GlobalKey<EduContEntryState> key, bool value) {
    setState(() {
      entries.firstWhere((entry) => entry['key'] == key)['graduated'] = value;
    });
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
              var entryData = entry.value;
              return EduContEntry(
                key: entryData['key'],
                context: context,
                title: 'Institution - ${index + 1}',
                nameController: entryData['nameController'],
                degreeController: entryData['degreeController'],
                descriptionController: entryData['descriptionController'],
                graduated: entryData['graduated'],
                addEntry: () => addEntry(index),
                deleteEntry: () => deleteEntry(entryData['key']),
                updateGraduated: (value) => updateGraduated(entryData['key'], value),
              );
            },
          ),
        ],
      ),
    );
  }
}