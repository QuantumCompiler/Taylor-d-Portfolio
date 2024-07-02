import 'package:flutter/material.dart';
import 'Context/ApplicationContentContext.dart';
import '../Globals/ApplicationsGlobals.dart';
import '../Utilities/ApplicationsUtils.dart';

class ApplicationContentList extends StatefulWidget {
  final ApplicationContent content;
  final Function refreshData;

  const ApplicationContentList({
    super.key,
    required this.content,
    required this.refreshData,
  });

  @override
  ApplicationContentListState createState() => ApplicationContentListState();
}

class ApplicationContentListState extends State<ApplicationContentList> {
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void disableOthers(Map<String, bool> checkedItems, String selectedKey) {
    checkedItems.forEach(
      (key, value) {
        if (key != selectedKey) {
          checkedItems[key] = false;
        }
      },
    );
  }

  void updateChecked(Map<String, bool> items, bool value, String key) {
    setState(
      () {
        disableOthers(items, key);
        items[key] = value;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * applicationsContainerWidth,
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            boxSliver(context, 'Select Job To Use In Application'),
            sliverList(widget.content, widget.content.jobs, widget.content.checkedJobs, updateChecked, widget.refreshData),
            boxSliver(context, 'Select Profile To Use In Application'),
            sliverList(widget.content, widget.content.profiles, widget.content.checkedProfiles, updateChecked, widget.refreshData)
          ],
        ),
      ),
    );
  }
}
