import 'package:flutter/material.dart';
import '../../Utilities/ApplicationsUtils.dart';
import '../../../Dashboard/Dashboard.dart';
import '../../../Globals/Globals.dart';
import '../../../Jobs/Edit/EditJob.dart';
import '../../../Profiles/Edit/EditProfile.dart';
import '../../../Themes/Themes.dart';

class ApplicationListItem extends StatefulWidget {
  final String name;
  final ApplicationContent content;
  final bool isChecked;
  final Function(bool) onChanged;
  final Function refreshData;

  const ApplicationListItem({
    super.key,
    required this.name,
    required this.content,
    required this.isChecked,
    required this.onChanged,
    required this.refreshData,
  });

  @override
  ApplicationListItemState createState() => ApplicationListItemState();
}

class ApplicationListItemState extends State<ApplicationListItem> {
  late bool isChecked;

  @override
  void initState() {
    super.initState();
    isChecked = widget.isChecked;
  }

  @override
  void didUpdateWidget(ApplicationListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isChecked != widget.isChecked) {
      isChecked = widget.isChecked;
    }
  }

  Future<void> updateJobsAndProfiles() async {
    await widget.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.name),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) {
              if (isJob(widget.content, widget.name)) {
                return EditJobPage(jobName: widget.name);
              } else if (isProfile(widget.content, widget.name)) {
                return EditProfilePage(profileName: widget.name);
              } else {
                return Dashboard();
              }
            },
          ),
        );
        await updateJobsAndProfiles();
      },
      trailing: Checkbox(
        value: isChecked,
        onChanged: (bool? value) {
          if (value != null) {
            setState(() {
              isChecked = value;
            });
            widget.onChanged(value);
          }
        },
      ),
    );
  }
}

SliverToBoxAdapter boxSliver(BuildContext context, String title) {
  return SliverToBoxAdapter(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: standardSizedBoxHeight),
        Text(
          title,
          style: TextStyle(
            color: themeTextColor(context),
            fontSize: secondaryTitles,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: standardSizedBoxHeight),
      ],
    ),
  );
}

SliverList sliverList(ApplicationContent content, List<dynamic> items, Map<String, bool> checkedItems, Function(Map<String, bool>, bool, String) onChanged, Function refreshData) {
  return SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, index) {
        final names = items[index].path.split('/').last;
        checkedItems.putIfAbsent(names, () => false);
        return ApplicationListItem(
          content: content,
          name: names,
          isChecked: checkedItems[names]!,
          onChanged: (value) {
            onChanged(checkedItems, value, names);
          },
          refreshData: refreshData,
        );
      },
      childCount: items.length,
    ),
  );
}
